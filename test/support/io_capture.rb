# frozen_string_literal: true

module TestSupport
  module IOCapture
    def capture_io
      require 'stringio'
      
      original_stdout = $stdout
      original_stderr = $stderr
      
      stdout = StringIO.new
      stderr = StringIO.new
      
      $stdout = stdout
      $stderr = stderr

      yield

      [stdout.string, stderr.string]
    ensure
      $stdout = original_stdout
      $stderr = original_stderr
    end
  end
end
