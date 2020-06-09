set :rails_env, 'development'

ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call unless ENV['DEPLOY']

server 'requests-dev.stanford.edu', user: 'requests', roles: %w(web db app)

set :bundle_without, %w{deployment test}.join(' ')

Capistrano::OneTimeKey.generate_one_time_key!
