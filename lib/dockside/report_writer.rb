# frozen_string_literal: true

module Dockside
  class ReportWriter
    def initialize(calculator)
      @calculator = calculator
    end

    def generate_report(sections, recommendations)
      report = @calculator.calculate_report(sections)

      puts "\n=== Dockerfile Analysis Report ==="

      # Report system commands first
      report_system_commands(report[:system_commands])

      # Report package analysis by section
      puts "\n📦 Base Packages (Production & Development):"
      report_section_packages(report[:base_packages], Constants::Stage::BASE)

      puts "\n🛠️  Build Packages (Gem Installation):"
      report_section_packages(report[:build_packages], Constants::Stage::BUILD)

      puts "\n🔧 Development Packages:"
      report_section_packages(report[:dev_packages], Constants::Stage::DEVELOPMENT)

      # Report recommendations
      report_recommendations(recommendations)
    end

    private

    def report_system_commands(system_commands)
      return if system_commands.empty?

      puts "\n🔍 Base Commands Found:"
      display_commands(system_commands[:base_commands])

      if system_commands[:dev_commands].any?
        puts "\n🔧 Development/Test Commands:"
        display_commands(system_commands[:dev_commands])
      end
    end

    def display_commands(commands)
      commands.each do |cmd, location|
        package = location[:package] || 'Unknown'
        
        if package != 'Unknown'
          puts "  - #{cmd} (provided by package: #{package})"
          puts "    Found in: #{location[:file]}:#{location[:line]}"
        else
          puts "  - #{cmd} (package not found)"
          puts "    Found in: #{location[:file]}:#{location[:line]}"
        end
      end
    end

    def report_section_packages(section_report, section_type)
      puts "\n  Installed packages:"
      section_report[:installed].each do |pkg, details|
        if details[:purposes].any?
          puts "  ✓ #{pkg} (#{details[:purposes].join(', ')})"
        elsif details[:known]
          puts "  ✓ #{pkg}"
        else
          puts "  ? #{pkg} (purpose unknown)"
        end
      end

      # Report missing packages
      if section_report[:missing].any?
        puts "\n  Missing packages:"
        section_report[:missing].sort.each do |pkg|
          puts "  ! #{pkg}"
        end
      end
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
