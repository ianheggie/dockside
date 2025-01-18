# frozen_string_literal: true

require 'set'
require 'English'
require 'forwardable'

module Dockside
  class PackageResolver

    def self.packages_provided_by(package)
      @packages_provided_by ||= {}
      @packages_provided_by[package] ||= _packages_provided_by(package)
    end

    def self.commands_provided_by(package)
      @commands_provided_by ||= {}
      @commands_provided_by[package] ||= _commands_provided_by(package)
    end

    # Detect and warn about package/command conflicts
    def self.detect_package_conflicts(packages, system_commands)
      conflicts = {}

      packages.each do |package|
        commands_provided_by(package).each do |cmd|
          if system_commands.key?(cmd)
            conflicts[cmd] ||= []
            conflicts[cmd] << package
          end
        end
      end

      if conflicts.any?
        puts "\n⚠️ Package/Command Conflicts Detected:"
        conflicts.each do |cmd, conflicting_packages|
          if conflicting_packages.size > 1
            puts "  - Command '#{cmd}' found in multiple packages: #{conflicting_packages.join(', ')}"
          end
        end
      end

      # Check for commands without packages
      missing_packages = system_commands.keys.reject do |cmd|
        packages.any? { |pkg| commands_provided_by(pkg).include?(cmd) }
      end

      if missing_packages.any?
        puts "\n⚠️ Commands without Package Resolution:"
        missing_packages.each do |cmd|
          puts "  - No package found for command: #{cmd}"
        end
      end
    end



    private

    # Memoize packages_provided_by with a recursive-safe cache
    def self._packages_provided_by(package, seen = Set.new)
      return [] if seen.include?(package)
      seen.add(package)

      # Skip library packages to optimize performance
      return [] if package.start_with?('lib')

      provides = []
      cmd = "apt-cache depends #{package} 2> /dev/null"
      puts "Executing: #{cmd}" if ENV['DEBUG']
      IO.popen(cmd, 'r', &:readlines).each do |line|
        # Depends and PreDepends - simple dependencies only not <debconf-2.0> for example
        # ignores list of other packages satisfying
        if line =~ /Depends:\s*([a-z]\S+)/
          provided_pkg = $1&.strip
          provides << provided_pkg

          # Recursively find packages provided by this package
          sub_provides = _packages_provided_by(provided_pkg, seen)
          provides.concat(sub_provides)
        end
      end

      puts "  DEBUG: Packages provided by #{package}: #{provides.inspect}" if ENV['DEBUG']
      provides.uniq
    end

    # Memoize commands_provided_by
    def self._commands_provided_by(package)
      packages = [package] + packages_provided_by(package)

      commands = []
      packages.each do |pkg|
        cmd = "apt-file list #{pkg} 2>/dev/null"
        puts "Executing: #{cmd}" if ENV['DEBUG']
        IO.popen(cmd, 'r', &:readlines).each do |line|
          commands << $3.strip if line =~ %r{^\S+: (/usr)?(/local)?/s?bin/([^/]+)$}
        end
      end

      puts "  DEBUG: Commands provided by #{package}: #{commands.inspect}" if ENV['DEBUG']
      commands.uniq
    end


  end
end
