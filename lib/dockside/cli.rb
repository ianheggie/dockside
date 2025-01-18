# frozen_string_literal: true

require_relative 'project_analyzer'

module Dockside
  class CLI
    def self.run(args)
      if args.length < 1 || args.length > 3
        puts "Usage: #{$PROGRAM_NAME} PROJECT_DIRECTORY [Dockerfile [Gemfile]]"
        puts "Analyzes Ruby project Dockerfile and Gemfile for package completeness"
        exit 1
      end

      project_dir = args[0]
      unless Dir.exist?(project_dir)
        puts "Error: Project directory '#{project_dir}' does not exist"
        exit 1
      end

      # Derive paths from project directory
      dockerfile_path = if args.length >= 2
                          if args[1].start_with?('/')
                            args[1]
                          else
                            File.join(project_dir, args[1])
                          end
                        else
                          File.join(project_dir, 'Dockerfile')
                        end
      gemfile_path = if args.length >= 3
                       if args[2].start_with?('/')
                         args[2]
                       else
                         File.join(project_dir, args[2])
                       end
                     else
                       File.join(project_dir, 'Gemfile')
                     end

      # Verify required files exist
      unless File.exist?(dockerfile_path)
        puts "Dockerfile not found at #{dockerfile_path}"
        exit 1
      end

      unless File.exist?(gemfile_path)
        puts "Gemfile not found at #{gemfile_path}"
        exit 1
      end

      analyzer = ProjectAnalyzer.new(
        dockerfile_path,
        gemfile_path,
        project_dir
      )
      analyzer.analyze
      return 0
    end
  end
end
