# frozen_string_literal: true

module Dockside
  class Dependency
    attr_reader :package, :reason, :type, :file, :line

    def initialize(package:, reason:, type:, file:, line:)
      @package = package
      @reason = reason
      @type = type # :base, :build, :development
      @file = file
      @line = line
    end

    def to_s
      "#{package} (#{reason} - found in #{file}:#{line})"
    end
  end
end
