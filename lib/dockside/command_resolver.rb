module Dockside
  class CommandResolver
    def initialize(project_root)
      @project_root = project_root
    end

    def find_package_for_command(cmd)
      @package_for_command ||= {}
      @package_for_command[cmd] ||= _find_package_for_command(cmd)
    end

    def self.command_exists?(cmd)
      return false if cmd.strip.empty?
      return false if cmd.match?(%r{[^A-Za-z0-9\-_/.]}) # Only allow safe characters

      # Check PATH
      ENV['PATH'].split(File::PATH_SEPARATOR).any? do |path|
        File.executable?(File.join(path, cmd))
      end
    end

    private

    def _find_package_for_command(cmd)
      return nil if cmd.strip.empty?

      # Check if it's a project-local executable
      if File.executable?(File.join(@project_root, cmd)) ||
        File.executable?(File.join(@project_root, 'bin', File.basename(cmd)))
        puts "  DEBUG: Ignoring project level executable!" if ENV['DEBUG']
        return :project_bin # Local executables don't need packages
      end

      # Common paths to search
      paths = [
        "/usr/bin/#{cmd}",
        "/usr/sbin/#{cmd}",
        "/bin/#{cmd}",
        "/sbin/#{cmd}",
        "/usr/local/bin/#{cmd}",
        "*bin*/#{cmd}", # Wildcard search
        cmd # Direct command name search
      ]

      # Check if it's a Ruby gem executable
      if self.class.command_exists?(cmd)
        which_output = `which #{cmd} 2> /dev/null`.strip
        if which_output.include?("/.gem/ruby/")
          puts "  DEBUG: Gem executables don't need packages!" if ENV['DEBUG']
          return :gem_bin
        end
        # shortcut searching ...
        puts "  DEBUG: found at #{which_output}" if ENV['DEBUG']
        paths = [which_output] if which_output.start_with?("/")
      end

      packages = Set.new

      # Try dpkg for installed packages
      paths.each do |path|
        next if path.include?('*') # Skip wildcard paths for dpkg
        dpkg_result = `dpkg -S #{path} 2>/dev/null`
        if $CHILD_STATUS.success?
          puts "  DEBUG: dpkg result: #{dpkg_result}" if ENV['DEBUG']
          packages.add(dpkg_result.split(':').first)
        end
      end

      if packages.empty?
        # Try apt-file search for each path
        paths.each do |path|
          apt_result = `apt-file search --package-only "#{path}" 2>/dev/null`
          if $CHILD_STATUS.success? && !apt_result.empty?
            result = apt_result.split("\n")
            puts "  DEBUG: apt-file result: #{result.inspect}" if ENV['DEBUG']
            packages.merge(result)
          end
        end
      end

      # If we found multiple packages, prefer exact matches
      if packages.any?
        puts "  DEBUG: prioritizing: #{packages.to_a.inspect}" if ENV['DEBUG']
        # Priority:
        # 1. Exact name match
        # 2. Package containing the command name
        # 3. First package found
        exact_match = packages.find { |pkg| pkg == cmd } ||
          packages.find { |pkg| pkg.include?(cmd) } ||
          packages.first
        puts "  DEBUG: returning: #{exact_match.inspect}" if ENV['DEBUG']
        return exact_match
      end

      nil
    end
  end
end
