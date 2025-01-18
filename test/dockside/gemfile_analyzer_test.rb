# frozen_string_literal: true

require 'test_helper'

module Dockside
  class GemfileAnalyzerTest < Minitest::Test
    def setup
      @fixtures_dir = File.expand_path("../fixtures/example1", __dir__)
    end

    def test_analyze_gemfile
      dockerfile = File.read(File.join(@fixtures_dir, 'Dockerfile'))
      analyzer = GemfileAnalyzer.new(
        File.join(@fixtures_dir, 'Gemfile'),
        dockerfile
      )
      results = analyzer.analyze
      
      # Should find mysql2 dependencies
      assert results.any? { |d| d.package == 'libmysqlclient' && d.type == :base },
        "Should find mysql2 runtime dependency"
      
      # Should not include dev gems in production
      refute results.any? { |d| d.package == 'debug' && d.type == :base },
        "Should not include dev gems in base dependencies"
    end
  end
end
