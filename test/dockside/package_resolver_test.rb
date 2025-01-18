# frozen_string_literal: true

require_relative '../test_helper'
require 'set'

module Dockside
  class PackageResolverTest < Minitest::Test
    include TestSupport::IOCapture

    def setup
      @fixtures_dir = File.expand_path("../fixtures/example1", __dir__)
    end

    def test_command_exists
      # Positive test for existing command
      assert PackageResolver.command_exists?('ls'), 
        "Should recognize existing system command"

      # Negative tests
      refute PackageResolver.command_exists?(''), 
        "Should reject empty command"
      refute PackageResolver.command_exists?('rm;ls'), 
        "Should reject commands with unsafe characters"
      refute PackageResolver.command_exists?('nonexistentcommand123456'), 
        "Should reject nonexistent command"
    end

    def test_packages_provided_by
      # Test a known package with known provides
      # ENV['DEBUG'] = '1'
      # Note: This might need adjustment based on your system's package configuration
      mysql_provides = PackageResolver.packages_provided_by('default-mysql-client')
      assert_kind_of Array, mysql_provides, 
        "Should return an array of provided packages"
      assert_includes mysql_provides, 'mysql-client-core-8.0',
                      'default-mysql-client provides mysql-client-core-8.0 package which includes mysqldump command'

      # Test with a non-existent package
      assert_equal [], PackageResolver.packages_provided_by('nonexistent-package'), 
        "Should return empty array for nonexistent package"
    end

    def test_commands_provided_by
      # Test a known package with known commands
      # Note: This might need adjustment based on your system's package configuration
      mysql_commands = PackageResolver.commands_provided_by('default-mysql-client')
      assert_includes mysql_commands, 'mysqldump',
        "Should include 'mysqldump' command for default-mysql-client package"
      
      # Test with a non-existent package
      assert_equal [], PackageResolver.commands_provided_by('nonexistent-package'), 
        "Should return empty array for nonexistent package"
    end
  end
end
