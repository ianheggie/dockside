# frozen_string_literal: true

require "test_helper"

class PackageDependenciesTest < Minitest::Test
  def test_mysql_client_dependencies
    # Test that default-mysql-client provides mysql-client-core
    deps = `apt-cache depends default-mysql-client 2>/dev/null`
    assert_includes deps, "Depends: mysql-client-8.0"
  end

  def test_gemfile_dependencies
    gemfile_path = File.expand_path("fixtures/example1/Gemfile", __dir__)
    dockerfile_content = File.read(File.expand_path("fixtures/example1/Dockerfile", __dir__))
    analyzer = Dockside::GemfileAnalyzer.new(gemfile_path, dockerfile_content)
    
    deps = analyzer.analyze
    
    # Check mysql2 gem dependencies
    mysql_deps = deps.select { |d| d.reason.include?("mysql2") }
    mysql_packages = mysql_deps.map(&:package)
    assert_includes mysql_packages, "libmysqlclient-dev", "Should require libmysqlclient-dev for building"
    assert_includes mysql_packages, "default-libmysqlclient-dev", "Should require default mysql client dev package"
    
    # Check net-ssh development dependency through capistrano
    ssh_deps = deps.select { |d| d.reason.include?("net-ssh") }
    assert ssh_deps.any? { |d| d.package == "libssl-dev" && d.type == :build }
  end
end
