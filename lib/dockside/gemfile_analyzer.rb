# frozen_string_literal: true

require 'bundler'
require_relative 'constants'
require_relative 'dependency'
require_relative 'package_maps'

module Dockside
  class GemfileAnalyzer
    include Constants

    def initialize(gemfile_path, dockerfile_content)
      @gemfile_path = gemfile_path
      @dockerfile_content = dockerfile_content
      @dependencies = []
    end

    def analyze
      return unless File.exist?(@gemfile_path)

      gemfile_content = File.read(@gemfile_path)
      lockfile_path = "#{@gemfile_path}.lock"
      return unless File.exist?(lockfile_path)

      # Add bundler dependencies since we have a Gemfile
      add_dependencies('bundler', gemfile_content, Stage::BASE)

      parser = Bundler::LockfileParser.new(File.read(lockfile_path))
      gemfile_groups = parse_gemfile_groups(gemfile_content)

      # Track native extension gems
      native_extension_gems = []

      parser.specs.each do |spec|
        # Get the groups this gem belongs to
        groups = gemfile_groups[spec.name] || [:default]
        common_type = groups.any? { |g| [:development, :test].include?(g) } ? Stage::DEVELOPMENT : Stage::BASE

        # Check for native extensions
        if spec.respond_to?(:extensions) && spec.extensions.any?
          native_extension_gems << spec.name
          add_dependencies(:extensions, gemfile_content, common_type)
        end

        # Add gem-specific dependencies
        add_dependencies(spec.name, gemfile_content, common_type)
      end

      # Add git if any gems use git sources
      if parser.sources.any? { |s| s.is_a?(Bundler::Source::Git) }
        add_dependency('git', 'Required for git gem sources', Stage::BASE, @gemfile_path, 1)
      end

      # Check for JavaScript runtime requirements
      if gemfile_content.match?(/execjs|terser/) && !gemfile_content.match?(/mini_racer/)
        line = find_gem_line(gemfile_content, 'execjs') ||
          find_gem_line(gemfile_content, 'terser')
        add_dependency('nodejs', 'Required for JavaScript runtime', Stage::BASE, @gemfile_path, line)
      end

      # Report on native extensions
      if native_extension_gems.any?
        puts "\n🔧 Gems with native extensions:"
        native_extension_gems.each do |gem_name|
          puts "  - #{gem_name}"
        end
      end

      @dependencies
    end

    private

    def add_dependencies(gem, gemfile_content, common_type)
      if PackageMaps::GEM_DEPENDENCIES.key?(gem)
        PackageMaps::GEM_DEPENDENCIES[gem].each do |package, type|
          type = common_type if type == Stage::BASE
          add_dependency(package,
                        "Required for #{gem} gem",
                        type,
                        @gemfile_path,
                        find_gem_line(gemfile_content, gem))
        end
      end
    end

    def add_dependency(package, reason, type, file, line)
      return if @dockerfile_content&.include?(package)

      @dependencies << Dependency.new(
        package: package,
        reason: reason,
        type: type,
        file: file,
        line: line
      )
    end

    def find_gem_line(content, gem_name)
      content.lines.find_index { |line| line.match?(/^\s*gem ['"]#{gem_name}['"]/) }&.+ 1
    end

    def parse_gemfile_groups(content)
      groups = {}
      current_groups = []

      content.lines.each do |line|
        if line =~ /group\s+:(\w+)(?:\s*,\s*:(\w+))*\s+do/
          current_groups = Regexp.last_match.captures.compact.map(&:to_sym)
        elsif line =~ /^\s*end\s*$/ && !current_groups.empty?
          current_groups = []
        elsif (gem_match = line.match(/^\s*gem\s+['"]([^'"]+)['"]/))
          gem_name = gem_match[1]
          groups[gem_name] = current_groups.empty? ? [:default] : current_groups.dup
        end
      end

      groups
    end
  end
end
