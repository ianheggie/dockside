# frozen_string_literal: true

require 'parser'
require 'parser/current'

module Dockside
  class SystemCallVisitor < Parser::AST::Processor
    attr_reader :commands, :file_path, :current_line

    def initialize(file_path)
      super()
      @file_path = file_path
      @current_line = 0
      @commands = {}
    end

    def on_send(node)
      @current_line = node.location.line

      # Check for system calls like system(), exec(), etc.
      _receiver, method_name, *args = *node
      if PackageMaps::SYSTEM_CALL_METHODS.include?(method_name.to_s)
        # Special handling for popen which has a mode argument
        if method_name.to_s == 'popen'
          # Only process the first argument for popen
          if args.first&.type == :str
            extract_command(args.first.children.first)
          end
        else
          # Handle both single string and array arguments
          args.each do |arg|
            case arg&.type
            when :str
              extract_command(arg.children.first)
            when :dstr
              # Handle string interpolation conservatively
              arg.children.each do |child|
                extract_command(child.children.first) if child&.type == :str
              end
            when :send
              # Handle method calls that return command strings
              extract_command(arg.children.last) if arg.children.last.is_a?(String)
            end
          end
        end
      end

      super
    end

    def on_xstr(node)
      @current_line = node.location.line
      # Backtick expressions come as xstr nodes
      node.children.each do |child|
        if child.type == :str
          extract_command(child.children.first)
        end
      end
      super
    end

    private

    def extract_command(cmd_str)
      return unless cmd_str.is_a?(String)
      return if cmd_str.strip.empty?

      # Skip comments
      return if cmd_str.strip.start_with?('#')

      # Extract just the first word as the command
      main_command = cmd_str.split(/\s+/).first

      # Only store commands that:
      # 1. Start with a lowercase letter
      # 2. Continue with lowercase letters, numbers, hyphen, underscore
      # 3. Don't start with '-'
      if main_command && 
         main_command.match?(/^[a-z][a-z0-9\-_]*$/) && 
         !main_command.start_with?('-')
        @commands[main_command] = @current_line
      end
    end
  end
end
