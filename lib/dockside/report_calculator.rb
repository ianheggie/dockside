# frozen_string_literal: true

module Dockside
  class ReportCalculator
    include Constants

    def initialize(dockerfile_content, system_commands, command_packages, dependencies)
      @dockerfile_content = dockerfile_content
      @system_commands = system_commands
      @command_packages = command_packages
      @dependencies = dependencies
    end

    def calculate_report(sections)
      {
        system_commands: analyze_system_commands,
        base_packages: analyze_section_packages(sections[Stage::BASE], Stage::BASE),
        build_packages: analyze_section_packages(sections[Stage::BUILD], Stage::BUILD),
        dev_packages: analyze_section_packages(sections[Stage::DEVELOPMENT], Stage::DEVELOPMENT)
      }
    end

    private

    def analyze_system_commands
      return {} unless @system_commands.any?

      # Group commands by type (production vs dev)
      base_commands, dev_commands = @system_commands.partition do |_, location|
        location[:type] != :development
      end

      {
        base_commands: base_commands.sort_by { |cmd, _| cmd }.to_h,
        dev_commands: dev_commands.sort_by { |cmd, _| cmd }.to_h
      }
    end

    def analyze_section_packages(installed_packages, section_type)
      # Get package dependencies and what they provide
      dependencies, provides = analyze_package_dependencies(installed_packages)

      # Get relevant package lists based on section type
      required_packages = case section_type
                          when Stage::BASE
                            select_command_packages(Stage::BASE)
                          when Stage::BUILD
                            get_build_packages_for_gems
                          when Stage::DEVELOPMENT
                            PackageMaps::DEV_PACKAGES.merge(select_command_packages(Stage::DEVELOPMENT))
                          end

      # Analyze installed packages
      installed_analysis = analyze_installed_packages(
        installed_packages, 
        dependencies, 
        provides, 
        required_packages
      )

      # Find missing packages
      missing_packages = find_missing_packages(required_packages, installed_packages, provides)

      {
        installed: installed_analysis,
        missing: missing_packages
      }
    end

    def analyze_installed_packages(installed_packages, dependencies, provides, required_packages)
      installed_analysis = {}

      installed_packages&.sort.each do |pkg|
        purpose = []

        # Check if this package provides any required commands
        dependencies.each do |cmd, provider|
          if provider == pkg && @system_commands.key?(cmd)
            purpose << "Provides command: #{cmd}"
          end
        end

        # Check if this package provides any required packages
        provides.each do |provided, provider|
          if provider == pkg && required_packages.key?(provided)
            purpose << "Provides package: #{provided}"
          end
        end

        installed_analysis[pkg] = {
          purposes: purpose,
          known: purpose.any? || required_packages.key?(pkg)
        }
      end

      installed_analysis
    end

    def find_missing_packages(required_packages, installed_packages, provides)
      required_packages.keys.reject do |pkg|
        installed_packages.include?(pkg) || provides.key?(pkg)
      end
    end

    def analyze_package_dependencies(installed_packages)
      command_provider = {}
      package_provider = {}

      installed_packages&.each do |package|
        # Get what this package provides
        PackageResolver.packages_provided_by(package).each do |pkg|
          package_provider[pkg] = package
        end

        # Get what commands this package provides
        PackageResolver.commands_provided_by(package).each do |command|
          command_provider[command] = package
        end
      end

      [command_provider, package_provider]
    end

    def get_build_packages_for_gems
      # Collect dev packages needed for gem compilation
      @dependencies
        .select { |d| d.type == Stage::BUILD }
        .map { |dep| [dep.package, dep.reason] }
        .to_h
    end

    def select_command_packages(type)
      # Collect packages needed for development commands
      @system_commands
        .select { |_, location| location[:type] == type }
        .map do |cmd, location|
          package = @command_packages[cmd]
          next if package.nil? || package.is_a?(Symbol)
          [package, "Required for #{type} command: #{cmd}"]
        end
        .compact
        .to_h
    end
  end
end
