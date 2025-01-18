# frozen_string_literal: true

require 'test_helper'

module Dockside
  class DockerfileAnalyzerTest < Minitest::Test
    def setup
      @fixtures_dir = File.expand_path("../fixtures/example1", __dir__)
    end

    def test_analyze_dockerfile
      analyzer = DockerfileAnalyzer.new(File.join(@fixtures_dir, 'Dockerfile'))
      content = File.read(File.join(@fixtures_dir, 'Dockerfile'))
      results = analyzer.analyze(content, ['mysql'], {'mysql' => 'default-mysql-client'})
      
      problems = []
      
      # Check for expected packages that should be present in Dockerfile
      expected_packages = {
        'default-mysql-client' => :base,
        'git' => :base
      }
      
      # These packages are already in the Dockerfile, so they shouldn't be in results
      expected_packages.each do |pkg, stage|
        if results.any? { |r| r.is_a?(Dependency) && r.package == pkg && r.type == stage }
          problems << "Package '#{pkg}' reported missing but exists in #{stage} stage"
        end
      end
      
      # Check for misplaced packages
      dev_packages = ['silversearcher-ag']
      dev_packages.each do |pkg|
        if results.any? { |r| r.is_a?(Dependency) && r.package == pkg && r.type == :production }
          problems << "Development package '#{pkg}' found in production"
        end
      end
      
      assert_empty problems, "\nDockerfile analysis issues:\n#{problems.join("\n")}"
    end
  end
end
