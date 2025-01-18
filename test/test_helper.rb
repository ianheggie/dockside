# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "dockside"

# Explicitly require just minitest/test to avoid Rails plugin conflicts
#require "minitest/test"
require "minitest/autorun"

require 'support/io_capture'
