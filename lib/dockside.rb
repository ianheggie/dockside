# frozen_string_literal: true

require_relative "dockside/cli"
require_relative "dockside/command_resolver"
require_relative "dockside/constants"
require_relative "dockside/dependency"
require_relative "dockside/dockerfile_analyzer"
require_relative "dockside/dockerfile_parser"
require_relative "dockside/file_scanner"
require_relative "dockside/gemfile_analyzer"
require_relative "dockside/command_analyzer"
require_relative "dockside/package_maps"
require_relative "dockside/package_resolver"
require_relative "dockside/project_analyzer"
require_relative "dockside/report_calculator"
require_relative "dockside/report_writer"
require_relative "dockside/system_call_visitor"
require_relative "dockside/version"

module Dockside
  class Error < StandardError; end
end
