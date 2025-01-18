# frozen_string_literal: true

require_relative 'constants'
require_relative 'dependency'
require_relative 'package_maps'
require_relative 'dockerfile_parser'

module Dockside
  class DockerfileAnalyzer
    include Constants

    def initialize(dockerfile_path)
      @dockerfile_path = dockerfile_path
      @dependencies = []
      @recommendations = []
    end

    def analyze(content, system_commands, command_packages)
      @dockerfile_content = content
      @parser = DockerfileParser.new(content)
      sections = @parser.sections

      analyze_dev_packages(sections)
      analyze_system_commands(sections, system_commands, command_packages)
      check_best_practices(content)

      [@dependencies, @recommendations, @parser.sections]
    end

    private

    def analyze_dev_packages(sections)
      PackageMaps::DEV_PACKAGES.each do |package, reason|
        next if sections[:development].include?(package)

        @dependencies << Dependency.new(
          package: package,
          reason: "Default package: #{reason}",
          type: :development,
          file: @dockerfile_path,
          line: @parser.find_package_line(package)
        )
      end
    end

    def analyze_system_commands(sections, system_commands, command_packages)
      system_commands.each do |cmd, location|
        package = command_packages[cmd]
        next if package.nil? || package.is_a?(Symbol)

        next unless package
        next if sections[:base].include?(package) ||
          sections[:build].include?(package) ||
          sections[:development].include?(package)

        @dependencies << Dependency.new(
          package: package,
          reason: "Required for system command: #{cmd}",
          type: location[:type],
          file: location[:file],
          line: location[:line]
        )
      end
    end

    def check_best_practices(content)
      # Check for apt-get update and install in the same RUN
      unless content.match?(/apt-get update.+?apt-get install/m)
        @recommendations << "Combine 'apt-get update' with 'apt-get install' in the same RUN instruction"
      end

      # Check for cleanup of apt cache
      unless content.include?('rm -rf /var/lib/apt/lists')
        @recommendations << "Clean up apt cache using 'rm -rf /var/lib/apt/lists'"
      end

      # Check for --no-install-recommends flag
      return if content.include?('--no-install-recommends')

      @recommendations << "Use '--no-install-recommends' flag with apt-get install to minimize image size"
    end
  end
end
