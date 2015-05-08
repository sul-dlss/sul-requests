begin
  require 'scss_lint/rake_task'
  SCSSLint::RakeTask.new do |t|
    t.config = '.scss-lint.yml'
  end
rescue LoadError
  puts 'Unable to load scss-lint'
end
