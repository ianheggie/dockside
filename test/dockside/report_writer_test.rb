# frozen_string_literal: true

require 'test_helper'

module Dockside
  class ReportWriterTest < Minitest::Test
    include Constants
    def setup
      @fixtures_dir = File.expand_path("../fixtures/example1", __dir__)
    end

    def test_report_display_format
      calculator = ReportCalculator.new(
        File.read(File.join(@fixtures_dir, 'Dockerfile')),
        {'mysql' => {file: 'test.rb', line: 1, type: :base}},
        {'mysql' => 'default-mysql-client'},
        []
      )
      
      writer = ReportWriter.new(calculator)
      
      output = StringIO.new
      $stdout = output
      sections = {
        Stage::BASE => ['git', 'default-mysql-client'],
        Stage::BUILD => [],
        Stage::DEVELOPMENT => []
      }
      writer.generate_report(sections, [])
      $stdout = STDOUT
      
      # Check overall report structure
      assert_match(/=== Dockerfile Analysis Report ===/, output.string, 
        "Report should have a title")
      assert_match(/🔍 Base Commands Found:/, output.string, 
        "Report should have a base commands section")
      assert_match(/📦 Base Packages/, output.string, 
        "Report should have a base packages section")
      assert_match(/🛠️  Build Packages/, output.string, 
        "Report should have a build packages section")
      assert_match(/🔧 Development Packages/, output.string, 
        "Report should have a development packages section")
    end

    def test_package_display_symbols
      calculator = ReportCalculator.new(
        File.read(File.join(@fixtures_dir, 'Dockerfile')),
        {'mysql' => {file: 'test.rb', line: 1, type: :base}},
        {'mysql' => 'default-mysql-client'},
        []
      )
      
      writer = ReportWriter.new(calculator)
      
      output = StringIO.new
      $stdout = output
      sections = {
        Stage::BASE => ['git', 'default-mysql-client'],
        Stage::BUILD => [],
        Stage::DEVELOPMENT => []
      }
      writer.generate_report(sections, [])
      $stdout = STDOUT
      
      # Check package display symbols
      assert_match(/✓ git/, output.string, 
        "Installed packages should be marked with ✓")
      assert_match(/✓ default-mysql-client/, output.string, 
        "Known packages should be marked with ✓")
      assert_match(/\? unknown_package/, output.string, 
        "Unknown packages should be marked with ?")
    end

    def test_recommendations_display
      calculator = ReportCalculator.new(
        File.read(File.join(@fixtures_dir, 'Dockerfile')),
        {},  # No system commands
        {},  # No command packages
        []
      )
      
      writer = ReportWriter.new(calculator)
      
      output = StringIO.new
      $stdout = output
      sections = {
        Stage::BASE => [],
        Stage::BUILD => [],
        Stage::DEVELOPMENT => []
      }
      recommendations = [
        "Consider using multi-stage builds",
        "Optimize package installation"
      ]
      writer.generate_report(sections, recommendations)
      $stdout = STDOUT

      # Check recommendation display
      assert_match(/📋 Recommendations:/, output.string, 
        "Report should have a recommendations section")
      assert_match(/Consider using multi-stage builds/, output.string, 
        "Report should display specific recommendations")
      assert_match(/Optimize package installation/, output.string, 
        "Report should display all recommendations")
    end
  end
end
