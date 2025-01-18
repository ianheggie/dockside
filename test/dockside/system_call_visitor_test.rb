# frozen_string_literal: true

require 'test_helper'
require 'tempfile'

module Dockside
  class SystemCallVisitorTest < Minitest::Test
    def setup
      @fixtures_dir = File.expand_path("../fixtures/example1", __dir__)
    end

    def test_visit_simple_system_call
      code = <<~RUBY
        system('mysql -u root')
        system('-not-a-command')
        system('valid_cmd')
      RUBY
      
      # Mirror how FileScanner handles parsing:
      begin
        buffer = Parser::Source::Buffer.new('(test)')
        buffer.source = code
        parser = Parser::CurrentRuby.new
        ast = parser.parse(buffer)
        
        visitor = SystemCallVisitor.new('test.rb')
        visitor.process(ast)
        
        problems = []
        
        # Check expected commands were found
        expected_commands = ['mysql', 'valid_cmd']
        missing_commands = expected_commands - visitor.commands.keys
        problems << "Missing commands: #{missing_commands.join(', ')}" if missing_commands.any?
        
        # Check invalid commands were excluded
        invalid_patterns = [/^-/, /[^a-z0-9\-_]/]
        invalid_commands = visitor.commands.keys.select do |cmd|
          invalid_patterns.any? { |pattern| cmd.match?(pattern) }
        end
        problems << "Invalid commands found: #{invalid_commands.join(', ')}" if invalid_commands.any?
        
        assert_empty problems, "\nSystem call visitor issues:\n#{problems.join("\n")}"
      rescue Parser::SyntaxError => e
        flunk "Syntax error: #{e.message}"
      rescue StandardError => e
        flunk "Error processing test code: #{e.message}"
      end
    end
  end
end
