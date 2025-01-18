# frozen_string_literal: true

require 'test_helper'

module Dockside
  class CommandAnalyzerTest < Minitest::Test
    def setup
      @fixtures_dir = File.expand_path("../fixtures/example1", __dir__)
    end

    def test_analyze_commands
      analyzer = CommandAnalyzer.new(@fixtures_dir)
      results = analyzer.analyze_commands(['mysql'])
      
      problems = []
      
      # Check expected commands were found
      expected_commands = {
        'mysql' => 'mysql-client-core-8.0'
      }
      
      expected_commands.each do |cmd, expected_pkg|
        actual_pkg = results[cmd]
        if actual_pkg.nil?
          problems << "Command '#{cmd}' not found - expected package '#{expected_pkg}'"
        elsif actual_pkg != expected_pkg
          problems << "Command '#{cmd}' resolved to '#{actual_pkg}' but expected '#{expected_pkg}'"
        end
      end
      
      # Check for unexpected commands
      unexpected = results.keys - expected_commands.keys
      problems << "Unexpected commands found: #{unexpected.join(', ')}" if unexpected.any?
      
      assert_empty problems, "\nPackage analysis issues:\n#{problems.join("\n")}"
    end
  end
end
