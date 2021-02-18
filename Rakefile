# frozen_string_literal: true

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake,
# and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

task default: [
  :javascript_tests,
  :rubocop,
  :scss_lint,
  :spec
]

task asset_paths: [:environment] do
  puts Rails.application.config.assets.paths
end

task javascript_tests: [:environment] do
  system 'yarn test'
end
