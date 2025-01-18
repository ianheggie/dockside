# frozen_string_literal: true

require 'test_helper'

module Dockside
  class ReportCalculatorTest < Minitest::Test
    include Constants

    def setup
      @fixtures_dir = File.expand_path("../fixtures/example1", __dir__)
    end

    def test_analyze_system_commands
      calculator = ReportCalculator.new(
        File.read(File.join(@fixtures_dir, 'Dockerfile')),
        {
          'mysql' => {file: 'test.rb', line: 1, type: :base},
          'git' => {file: 'test.rb', line: 2, type: :development}
        },
        {'mysql' => 'default-mysql-client', 'git' => 'git-core'},
        []
      )

      sections = {
        Stage::BASE => ['git'],
        Stage::BUILD => [],
        Stage::DEVELOPMENT => []
      }

      report = calculator.calculate_report(sections)

      # Check system commands structure
      assert_includes report, :system_commands
      assert_includes report[:system_commands], :base_commands
      assert_includes report[:system_commands], :dev_commands

      # Verify base commands
      assert_equal 1, report[:system_commands][:base_commands].size
      assert_includes report[:system_commands][:base_commands].keys, 'mysql'

      # Verify dev commands
      assert_equal 1, report[:system_commands][:dev_commands].size
      assert_includes report[:system_commands][:dev_commands].keys, 'git'
    end

    def test_analyze_section_packages
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

      sections = {
        Stage::BASE => ['git', 'default-mysql-client'],
        Stage::BUILD => [],
        Stage::DEVELOPMENT => []
      }

      report = calculator.calculate_report(sections)

      # Check base packages structure
      assert_includes report, :base_packages
      assert_includes report[:base_packages], :installed
      assert_includes report[:base_packages], :missing

      # Verify installed packages
      installed = report[:base_packages][:installed]
      assert_includes installed, 'git'
      assert_includes installed, 'default-mysql-client'

      # Verify package purposes
      mysql_pkg_details = installed['default-mysql-client']
      assert_equal true, mysql_pkg_details[:known]
      assert_includes mysql_pkg_details[:purposes], 'Provides command: mysql'
    end

    def test_find_missing_packages
      calculator = ReportCalculator.new(
        File.read(File.join(@fixtures_dir, 'Dockerfile')),
        {'mysql' => {file: 'test.rb', line: 1, type: :base}},
        {'mysql' => 'default-mysql-client'},
        []
      )

      sections = {
        Stage::BASE => [],
        Stage::BUILD => [],
        Stage::DEVELOPMENT => []
      }

      report = calculator.calculate_report(sections)

      # Check base packages missing packages
      base_missing = report[:base_packages][:missing]
      assert_includes base_missing, 'default-mysql-client'
    end

    def test_development_packages
      calculator = ReportCalculator.new(
        File.read(File.join(@fixtures_dir, 'Dockerfile')),
        {'wget' => {file: 'test.rb', line: 1, type: :development}},
        {'wget' => 'wget'},
        []
      )

      sections = {
        Stage::BASE => [],
        Stage::BUILD => [],
        Stage::DEVELOPMENT => ['wget']
      }

      report = calculator.calculate_report(sections)

      # Check development packages
      dev_packages = report[:dev_packages]
      assert_includes dev_packages[:installed], 'wget'
      assert_includes PackageMaps::DEV_PACKAGES.keys, 'wget'
    end
  end
end
