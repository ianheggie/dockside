# frozen_string_literal: true

require 'test_helper'

module Dockside
  class CLITest < Minitest::Test
    def setup
      # Do nothing
    end

    def teardown
      # Do nothing
    end

    def test_cli_with_good_dockerfile
      @fixtures_dir = File.expand_path("../../fixtures/example1", __FILE__)
      dockerfile_path = File.join(@fixtures_dir, 'Dockerfile-good')
  
      output = capture_io do
        CLI.run([@fixtures_dir, dockerfile_path])
      end

      output_str = output.first

      # Check for missing packages
      missing_packages = output_str.scan(/Missing packages:.*?(?=\n\n|\z)/m).first
      assert_nil missing_packages, 
        "Expected no missing packages, but found:\n#{missing_packages}"

      # Check for packages with unknown purpose
      unknown_packages = output_str.scan(/\?\s.*\(purpose unknown\)/)
      assert_empty unknown_packages, 
        "Expected no packages with unknown purpose, but found:\n#{unknown_packages.join("\n")}"
    end
  end
end
