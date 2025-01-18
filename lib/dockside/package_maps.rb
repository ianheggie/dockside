# frozen_string_literal: true

module Dockside
  module PackageMaps
    # Packages only needed in development/test
    DEV_PACKAGES = {
      'silversearcher-ag' => 'Fast code searching tool',
      'direnv' => 'Directory-specific environment variables',
      'unzip' => 'Extract zip archives',
      'wget' => 'Download files',
      'curl' => 'Transfer data via a URL',
      'zip' => 'Create zip archives',
    }.freeze

    # Maps gems to dependencies
    GEM_DEPENDENCIES = {
      :extensions => [
        ['build-essential', :build],
        ['pkg-config', :build]
      ],
      'mysql2' => [
        ['libmysqlclient', :base],
        ['libmysqlclient-dev', :build],
        ['default-mysql-client', :base],
        ['default-libmysqlclient-dev', :build]
      ],
      'nokogiri' => [
        ['libxml2', :base],
        ['libxslt1.1', :base],
        ['libxml2-dev', :build],
        ['libxslt1-dev', :build],
        ['pkg-config', :build]
      ],
      'net-ssh' => [
        ['libssl3', :development],
        ['libssl-dev', :build]
      ],
      'bundler' => [
        ['git', :base],
        ['ca-certificates', :base]
      ]
    }.freeze

    # Maps runtime libraries to their build-time dev packages
    LIBRARY_DEV_MAPPING = {
      'libmysqlclient' => 'libmysqlclient-dev',
      'libxml2' => 'libxml2-dev',
      'libxslt1.1' => 'libxslt1-dev',
      'libcurl4' => 'libcurl4-openssl-dev',
      'libffi8ubuntu1' => 'libffi-dev',
      'libreadline8' => 'libreadline-dev',
      'libsqlite3-0' => 'libsqlite3-dev',
      'libssl3' => 'libssl-dev',
      'libyaml-0-2' => 'libyaml-dev',
      'zlib1g' => 'zlib1g-dev'
    }.freeze

    SYSTEM_CALL_METHODS = %w[
      system exec ` spawn popen popen2 popen3 open3 %x
      capture2e capture2 capture3 pipeline_r pipeline_w pipeline pipeline_start
    ].freeze
  end
end
