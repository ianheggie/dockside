# frozen_string_literal: true

module Dockside
  class ReportWriter
    def initialize(dockerfile_content, system_commands, command_packages, dependencies)
      @dockerfile_content = dockerfile_content
      @system_commands = system_commands
      @command_packages = command_packages
      @dependencies = dependencies
    end

    def generate_report(sections, recommendations)
      puts "\n=== Dockerfile Analysis Report ==="

      # Report system commands first
      report_system_commands

      # Report package analysis by section
      puts "\n📦 Base Packages (Production & Development):"
      analyze_section_packages(sections[Constants::Stage::BASE], Constants::Stage::BASE)

      puts "\n🛠️  Build Packages (Gem Installation):"
      analyze_section_packages(sections[Constants::Stage::BUILD], Constants::Stage::BUILD)

      puts "\n🔧 Development Packages:"
      analyze_section_packages(sections[Constants::Stage::DEVELOPMENT], Constants::Stage::DEVELOPMENT)

      # Report recommendations
      report_recommendations(recommendations)
    end

    private

    def report_system_commands
      return unless @system_commands.any?

      puts "\n🔍 Base Commands Found:"
      # Group commands by type (production vs dev)
      base_commands, dev_commands = @system_commands.partition do |_, location|
        location[:type] != :development
      end

      # Base commands - now sorted
      display_commands(base_commands.sort_by { |cmd, _| cmd })

      # Development commands - now sorted
      if dev_commands.any?
        puts "\n🔧 Development/Test Commands:"
        display_commands(dev_commands.sort_by { |cmd, _| cmd })
      end
    end

    def display_commands(commands)
      commands.each do |cmd, location|
        package = @command_packages[cmd]
        next if package.is_a?(Symbol)

        if package
          puts "  - #{cmd} (provided by package: #{package})"
          puts "    Found in: #{location[:file]}:#{location[:line]}"
        else
          puts "  - #{cmd} (package not found)"
          puts "    Found in: #{location[:file]}:#{location[:line]}"
        end
      end
    end

    def analyze_section_packages(installed_packages, section_type)
      # Get package dependencies and what they provide
      dependencies, provides = analyze_package_dependencies(installed_packages)

      # Get relevant package lists based on section type
      required_packages = case section_type
                          when Constants::Stage::BASE
                            select_command_packages(Constants::Stage::BASE)
                          when Constants::Stage::BUILD
                            get_build_packages_for_gems
                          when Constants::Stage::DEVELOPMENT
                            PackageMaps::DEV_PACKAGES.merge(select_command_packages(Constants::Stage::DEVELOPMENT))
                          end

      # Check installed packages
      puts "\n  Installed packages:"
      installed_packages.sort.each do |pkg|
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

        if purpose.any?
          puts "  ✓ #{pkg} (#{purpose.join(', ')})"
        elsif required_packages.key?(pkg)
          puts "  ✓ #{pkg} (#{required_packages[pkg]})"
        else
          puts "  ? #{pkg} (purpose unknown)"
        end
      end

      # Check for missing packages, accounting for provided packages
      missing = required_packages.keys.reject do |pkg|
        installed_packages.include?(pkg) || provides.key?(pkg)
      end

      if missing.any?
        puts "\n  Missing packages:"
        missing.sort.each do |pkg|
          puts "  ! #{pkg} (#{required_packages[pkg]})"
        end
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
      dev_packages = {}

      @dependencies.select { |d| d.type == Constants::Stage::BUILD }.each do |dep|
        dev_packages[dep.package] = dep.reason
      end

      dev_packages
    end

    def select_command_packages(type)
      # Collect packages needed for development commands
      packages = {}

      @system_commands.each do |cmd, location|
        next unless location[:type] == type
        package = @command_packages[cmd]
        next if package.nil? || package.is_a?(Symbol)

        packages[@command_packages[cmd]] = "Required for #{type} command: #{cmd}"
      end

      packages
    end

    def report_recommendations(recommendations)
      return if recommendations.empty?

      puts "\n📋 Recommendations:"
      recommendations.each do |rec|
        puts "  - #{rec}"
      end
    end
  end
end
