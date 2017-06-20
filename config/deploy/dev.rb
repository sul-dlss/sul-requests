set :rails_env, 'development'

server 'requests-dev.stanford.edu', user: 'requests', roles: %w(web db app)

set :bundle_without, %w{deployment test}.join(' ')

Capistrano::OneTimeKey.generate_one_time_key!
