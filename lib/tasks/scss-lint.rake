begin
  require 'scss_lint/rake_task'
  SCSSLint::RakeTask.new do |t|
    t.config = '.scss-style.yml'
  end
rescue LoadError
  puts 'Unable to load scss-lint'
end
