# frozen_string_literal: true

require 'test_helper'

module Dockside
  class DockerfileParserTest < Minitest::Test
    include Constants
    def setup
      @fixtures_dir = File.expand_path("../fixtures/example1", __dir__)
    end

    def test_parse_dockerfile_sections
      content = File.read(File.join(@fixtures_dir, 'Dockerfile'))
      parser = DockerfileParser.new(content)
      sections = parser.sections
      
      problems = []
      
      # Check base stage packages
      expected_base = ['git', 'ca-certificates', 'libxml2', 'default-mysql-client']
      missing_base = expected_base - sections[Stage::BASE]
      extra_base = sections[Stage::BASE] - expected_base
      
      problems << "Missing base packages: #{missing_base.join(', ')}" if missing_base.any?
      problems << "Unexpected base packages: #{extra_base.join(', ')}" if extra_base.any?
      
      # Check no dev tools leaked into production
      dev_tools = ['silversearcher-ag', 'curl']
      leaked_dev = sections[Stage::PRODUCTION] & dev_tools
      problems << "Development tools found in production: #{leaked_dev.join(', ')}" if leaked_dev.any?
      
      assert_empty problems, "\nDockerfile parsing issues:\n#{problems.join("\n")}"
    end
  end
end
