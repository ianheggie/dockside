# frozen_string_literal: true

require_relative 'constants'
require_relative 'file_scanner'
require_relative 'command_analyzer'
require_relative 'dockerfile_analyzer'
require_relative 'gemfile_analyzer'
require_relative 'report_writer'

module Dockside
  class ProjectAnalyzer
    include Constants

    def initialize(dockerfile_path, gemfile_path, project_root)
      @dockerfile_path = dockerfile_path
      @gemfile_path = gemfile_path
      @project_root = project_root
      @dependencies = []
    end

    def analyze
      return puts "Dockerfile not found at #{@dockerfile_path}" unless File.exist?(@dockerfile_path)
      return puts "Gemfile not found at #{@gemfile_path}" unless File.exist?(@gemfile_path)
      return puts "Project root not found at #{@project_root}" unless Dir.exist?(@project_root)

      @dockerfile_content = File.read(@dockerfile_path)

      puts '🔍 Analyzing project files...'
      file_scanner = FileScanner.new(@project_root)
      @system_commands = file_scanner.scan_ruby_files

      puts '📦 Analyzing packages for commands...'
      package_analyzer = CommandAnalyzer.new(@project_root)
      @command_packages = package_analyzer.analyze_commands(@system_commands)

      puts '🔍 Analyzing gemfile dependencies...'
      gemfile_analyzer = GemfileAnalyzer.new(@gemfile_path, @dockerfile_content)
      @dependencies.concat(gemfile_analyzer.analyze)

      puts '📦 Analyzing Dockerfile ...'
      dockerfile_analyzer = DockerfileAnalyzer.new(@dockerfile_path)
      deps, recommendations, sections = dockerfile_analyzer.analyze(@dockerfile_content, @system_commands, @command_packages)
      @dependencies.concat(deps)

      puts '📦 Calculating report ...'
      calculator = ReportCalculator.new(@dockerfile_content, @system_commands, @command_packages, @dependencies)
      calculations = calculator.calculate_report(sections)
      calculations[:recommendations] = recommendations

      puts '📦 Generating reports ...'

      reporter = ReportWriter.new(calculations)
      reporter.generate_report
      @dependencies # Return the dependencies
    end
  end
end
