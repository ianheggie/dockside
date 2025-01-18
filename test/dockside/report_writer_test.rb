# frozen_string_literal: true

require 'test_helper'

module Dockside
  class ReportWriterTest < Minitest::Test
    include Constants
    def setup
      @fixtures_dir = File.expand_path("../fixtures/example1", __dir__)
    end

    def test_generate_basic_report
      calculator = ReportCalculator.new(
        File.read(File.join(@fixtures_dir, 'Dockerfile')),
        {'mysql' => {file: 'test.rb', line: 1, type: :base}},
        {'mysql' => 'default-mysql-client'},
        [Dependency.new(
          package: 'default-mysql-client',
          reason: 'Required for mysql command',
          type: :base,
          file: 'test.rb',
          line: 1
        )]
      )
      
      writer = ReportWriter.new(calculator)
      
      output = StringIO.new
      $stdout = output
      sections = {
        Stage::BASE => ['git'],
        Stage::BUILD => [],
        Stage::DEVELOPMENT => []
      }
      writer.generate_report(sections, [])
      $stdout = STDOUT
      
      # Should mention found dependency
      assert_match(/default-mysql-client/, output.string,
        "Report should mention required mysql package")
        
      # Should not complain about existing package
      refute_match(/missing.*git/, output.string,
        "Report should not complain about git which is present")
    end

    def test_gem_package_reporting
      # Simulate a scenario with bundler and nokogiri
      calculator = ReportCalculator.new(
        File.read(File.join(@fixtures_dir, 'Dockerfile')),
        {},  # No system commands
        {},  # No command packages
        [
          Dependency.new(
            package: 'bundler',
            reason: 'Gem dependency',
            type: :base,
            file: 'Gemfile',
            line: 1
          ),
          Dependency.new(
            package: 'nokogiri',
            reason: 'Gem dependency',
            type: :base,
            file: 'Gemfile',
            line: 2
          )
        ]
      )
      
      writer = ReportWriter.new(calculator)
      
      output = StringIO.new
      $stdout = output
      sections = {
        Stage::BASE => [],
        Stage::BUILD => [],
        Stage::DEVELOPMENT => []
      }
      writer.generate_report(sections, [])
      $stdout = STDOUT

      # Check for packages required by bundler
      PackageMaps::GEM_DEPENDENCIES['bundler'].each do |pkg_info|
        pkg, _ = pkg_info
        assert_match(/#{pkg}/, output.string, 
          "Report should mention package #{pkg} required for bundler")
      end

      # Check for packages required by nokogiri
      PackageMaps::GEM_DEPENDENCIES['nokogiri'].each do |pkg_info|
        pkg, _ = pkg_info
        assert_match(/#{pkg}/, output.string, 
          "Report should mention package #{pkg} required for nokogiri")
      end
    end
  end
end
