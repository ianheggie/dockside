# frozen_string_literal: true

require_relative '../test_helper'
require 'set'

module Dockside
  class CommandResolverTest < Minitest::Test
    include TestSupport::IOCapture

    def setup
      @fixtures_dir = File.expand_path("../fixtures/example1", __dir__)
      @resolver = CommandResolver.new(@fixtures_dir)
    end

    def test_find_package_for_command
      # Should find common package
      mysql_pkg = @resolver.find_package_for_command('mysqldump')
      assert_equal 'mysql-client-core-8.0', mysql_pkg,
                   "Should resolve mysql command to correct package"

      # Should not find nonexistent command
      nonexistent = @resolver.find_package_for_command('nonexistentcmd')
      assert_nil nonexistent,
                 "Should return nil for nonexistent command"
    end
  end
end
