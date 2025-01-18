# frozen_string_literal: true

require_relative 'constants'

module Dockside
  class DockerfileParser
    include Constants

    def initialize(content)
      @content = content
    end

    def sections
      @sections ||= parse_sections
      @sections.default = [] # Provide default empty array for missing sections
      @sections
    end

    def include?(package)
      sections.values.any? { |pkgs| pkgs.include?(package) }
    end

    def find_package_line(package)
      @content.lines.find_index { |line| line.include?(package) }&.+ 1
    end

    private

    def parse_sections
      sections = DEFAULT_SECTIONS.dup

      # Split into sections based on FROM directives
      dockerfile_parts = @content.split(/^FROM\s+/)
      dockerfile_parts.shift # Remove empty first section

      # Parse each section
      dockerfile_parts.each do |section|
        case section
        when /^\S+\s+AS\s+base/
          sections[Stage::BASE] = extract_packages(section)
        when /^\S+\s+AS\s+build-packages/
          sections[Stage::BUILD] = extract_packages(section)
        when /^\S+\s+AS\s+development/
          sections[Stage::DEVELOPMENT] = extract_packages(section)
        end
      end

      sections
    end

    def extract_packages(section)
      packages = []
      # Remove comment lines first
      cleaned_section = section.lines.reject { |line| line.strip.start_with?('#') }.join
      cleaned_section.scan(/apt-get\s+install\s+(?:-\S+\s+)*(.+?)\s*&&/m) do |match|
        # Split on whitespace and remove any trailing backslashes
        match[0].split.map { |p| p.chomp('\\').strip }.each do |package|
          packages << package if package =~ /^[a-z0-9][a-z0-9+.-]+$/
        end
      end
      packages.uniq
    end
  end
end
