# frozen_string_literal: true

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake,
# and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

task default: [
  :javascript_tests,
  :rubocop,
  :spec
]

task javascript_tests: [:environment] do
  cmd = 'yarn test'
  success = system(cmd)

  if success
    puts 'JavaScript tests passed'
  else
    puts 'JavaScript tests failed'
    exit(1)
  end
end
