# frozen_string_literal: true

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  # We used to print a warning message here but we didn't want to see it every
  # 24 hours in cron output, so instead, no-op.
end
