# frozen_string_literal: true

require 'test_helper'

module Dockside
  class ProjectAnalyzerTest < Minitest::Test
    def setup
      @fixtures_dir = File.expand_path("../fixtures/example1", __dir__)
    end

    def test_analyzer_happy_path
      analyzer = ProjectAnalyzer.new(
        File.join(@fixtures_dir, 'Dockerfile'),
        File.join(@fixtures_dir, 'Gemfile'),
        @fixtures_dir
      )
      results = analyzer.analyze
      
      refute_nil results, "Expected analyzer to return results"
      
      # Should find mysql2 gem needs mysql client
      assert results.any? { |d| d.package == 'mysql-client-core-8.0' },
        "Should detect mysql2 gem needs mysql client"
      
      # Should not complain about git which is already in Dockerfile
      refute results.any? { |d| d.package == 'git' },
        "Should not flag git as missing since it's in Dockerfile"
    end
  end
end
