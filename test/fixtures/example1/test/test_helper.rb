require 'open3'

def a_test_function
  _stdout_and_stderr, _status = Open3.capture2e('crontab -l')
  # Process.spawn - non-blocking
  _pid = Process.spawn('top')
  _stdout, _stderr, _status = Open3.pipeline_r('df -h', 'grep /dev')
  _result = popen2('vmstat 10')
  _result = popen3("ls #{dir}")
  
  # Additional system call examples
  Open3.pipeline_w('gzip') { |stdin| stdin.write('data') }
  Open3.pipeline('sort', 'uniq')
  Open3.pipeline_start('sed s/foo/bar/')
  _stdout, _status = Open3.capture2('date')
  Open3.open3('awk "{print $1}"')
end
