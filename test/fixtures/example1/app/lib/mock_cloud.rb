require 'fileutils'

##
# Mock implementation of Cloud for development and test environments
#
# @api private
# @environment development, test
# @see Cloud#factory
#
# This class provides a file-system based implementation of the Cloud interface
##

class MockCloud
  def list
    IO
      .popen("find tmp/cloud", 'r', &:readlines)
      .map(&:chomp)
  end
end

