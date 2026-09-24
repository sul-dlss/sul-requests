set :rails_env, 'production'
set :application, 'mylibrary'
set :deploy_to, '/opt/app/mylibrary/mylibrary'

server 'mylibrary-prod-a.stanford.edu', user: 'mylibrary', roles: %w[web db app production_cron]
server 'mylibrary-prod-b.stanford.edu', user: 'mylibrary', roles: %w[web app]


set :bundle_without, %w{deployment development test}.join(' ')

Capistrano::OneTimeKey.generate_one_time_key!
