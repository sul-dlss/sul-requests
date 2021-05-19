# frozen_string_literal: true

begin
  require 'scss_lint/rake_task'
  SCSSLint::RakeTask.new do |t|
    t.config = '.scss-lint.yml'
  end
rescue LoadError
  # We used to print a warning message here but we didn't want to see it every
  # 24 hours in cron output, so instead, no-op.
end
