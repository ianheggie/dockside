# frozen_string_literal: true

require_relative 'command_resolver'
require_relative 'dependency'

module Dockside
  class CommandAnalyzer
    def initialize(project_root)
      @project_root = project_root
      @command_packages = {}
    end

    def analyze_commands(system_commands)
      ensure_apt_file_available
      resolve_command_packages(system_commands)
      @command_packages
    end

    private

    def resolve_command_packages(system_commands)
      resolver = CommandResolver.new(@project_root)
      system_commands.each do |cmd, location|
        package = resolver.find_package_for_command(cmd)
        @command_packages[cmd] = package if package
      end
    end

    def ensure_apt_file_available
      return if CommandResolver.command_exists?('apt-file')

      puts "Installing apt-file for better package detection..."
      system('sudo apt-get update && sudo apt-get install -y apt-file')

      puts "Updating apt-file database..."
      system('sudo apt-file update')
    end
  end
end
