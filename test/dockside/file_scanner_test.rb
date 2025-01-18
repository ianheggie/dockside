# frozen_string_literal: true

require 'test_helper'
require 'yaml'

module Dockside
  class FileScannerTest < Minitest::Test
    def setup
      @project_dir = File.expand_path("../fixtures/example1", __dir__)
      @scanner = Dockside::FileScanner.new(@project_dir)
      @commands = @scanner.scan_ruby_files
    end

    # ruby_command, shell_command, file
    CALLS = [
      %w[system mysqldump lib/tasks/db.rake],
      %w[exec free script/a_script],
      %w[capture2e crontab test/test_helper.rb],
      %w[` hostname db/seeds.rb],
      %w[spawn top test/test_helper.rb],
      %w[popen find app/lib/mock_cloud.rb],
      %w[popen2 vmstat test/test_helper.rb],
      %w[popen3 ls test/test_helper.rb],
      %w[pipeline_r df test/test_helper.rb],
      %w[capture3 who bin/a_bin],
      %w[%x uptime bin/a_bin],
      %w[pipeline_w gzip test/test_helper.rb],
      %w[pipeline sort test/test_helper.rb],
      %w[pipeline_start sed test/test_helper.rb],
      %w[capture2 date test/test_helper.rb],
      %w[open3 awk test/test_helper.rb],
    ]

    def test_example_files_are_setup
      CALLS.each do |ruby_command, shell_command, file|
        contents = IO.read(File.join(@project_dir, file))
        assert_includes contents, ruby_command, "Expected #{file} to include #{ruby_command}"
        assert_includes contents, shell_command, "Expected #{file} to include #{shell_command}"
      end
    end

    def test_scanner_finds_commands
      CALLS.map do |ruby_command, shell_command, file|
        command = @commands[shell_command]
        assert command,
               "Expected to find #{shell_command} from source: #{file} with #{ruby_command} expression"
        assert_equal command[:file], file
      end
    end

    def test_does_not_treat_args_as_commands
      # puts @commands.to_yaml
      refute_includes @commands.keys, 'r'
      refute @commands.keys.any? { |cmd| cmd.start_with?('-') }, "Found command starting with '-'"
    end
  end
end
