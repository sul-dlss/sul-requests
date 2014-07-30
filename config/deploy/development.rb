server 'sulwebappdev2.stanford.edu', user: 'requests', roles: %w{web db app}

Capistrano::OneTimeKey.generate_one_time_key!
set :rails_env, "development"
