# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"

Minitest::TestTask.create do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_globs = ENV["TEST"] ? ENV["TEST"] : "test/**/*_test.rb"
  t.extra_args << "-v" if ENV['VERBOSE'] || ENV['DEBUG']
  if ENV['SEED']
    t.extra_args << "--seed"
    t.extra_args << ENV.fetch('SEED')
  end
end

task default: :test
