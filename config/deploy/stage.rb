set :rails_env, 'production'

set :bundle_without, %w{deployment test}.join(' ')
