# frozen_string_literal: true

require 'find'
require 'parser'
require 'parser/current'
require_relative 'system_call_visitor'
require_relative 'constants'

module Dockside
  class FileScanner
    include Constants
    attr_reader :project_root

    def initialize(project_root)
      @project_root = project_root
      @system_commands = {} # command => {file: X, line: Y, type: TYPE}
    end

    def scan_ruby_files
      Dir.chdir(@project_root) do
        # Scan different directories with appropriate dependency types
        scan_directory('app', :base)
        scan_directory('lib', :base)
        scan_directory('db', :base)

        # bin/* scripts are common dependencies
        scan_directory('bin', :base)
        scan_directory('ansible', :base)
        scan_directory('inventory', :base)

        # Lowest priority
        scan_directory('test', :development)
        scan_directory('script', :development)
      end
      @system_commands
    end

    private

    def scan_directory(dir, default_type)
      return unless Dir.exist?(dir)

      count = 0
      Find.find(dir) do |path|
        next unless File.file?(path)

        ext = File.extname(path)
        next if ext != '' && !%w[.rb .rake].include?(ext)

        content = File.read(path)
        next if ext == '' && !content.start_with?('#!/usr/bin/env ruby')

        parse_ruby_contents(content, default_type, path)
        count += 1
      end
      puts "  🔍 Analyzed #{count} files in #{dir} [#{default_type}]"
    end

    def parse_ruby_contents(content, default_type, path)
      begin
        # puts "ZZ #{path}"
        # Check for @environment tag to override default dependency type
        type = default_type
        if content =~ /@environment\s+([^#\n]+)/
          environments = $1.downcase.split(/[,\s]+/)
          if environments.any? { |e| %w[development test].include?(e) } && !environments.include?('production')
            type = :development
          end
        end
        buffer = Parser::Source::Buffer.new(path)
        buffer.source = content
        parser = Parser::CurrentRuby.new
        ast = parser.parse(buffer)

        visitor = SystemCallVisitor.new(path)
        visitor.process(ast)
        visitor.commands.each do |cmd, line|
          # Keep the first (highest priority)
          @system_commands[cmd] ||= {
            file: path,
            line: line,
            type: type
          }
        end
      rescue Parser::SyntaxError => e
        puts "⚠️  Syntax error in #{path}: #{e.message}"
      rescue StandardError => e
        puts "⚠️  Error processing #{path}: #{e.message}"
      end
    end
  end
end
