# frozen_string_literal: true

module Dockside
  module Constants
    # Package types/stages in Dockerfile
    module Stage
      BASE = :base
      BUILD = :build
      DEVELOPMENT = :development
      PRODUCTION = :production

      ALL = [BASE, BUILD, DEVELOPMENT, PRODUCTION].freeze
    end

    # Default sections in Dockerfile
    DEFAULT_SECTIONS = {
      Stage::BASE => [], # Common packages for both prod & dev
      Stage::BUILD => [], # Packages needed for gem installation
      Stage::DEVELOPMENT => [] # Development-only packages
    }.freeze
  end
end
