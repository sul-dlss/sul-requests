set :rails_env, "development"
set :deployment_host, "sulwebappdev2"
set :repository,  "."
set :branch, "rails3"
set :bundle_without, [:deployment,:production]

role :web, deployment_host
role :app, deployment_host
role :db,  deployment_host, :primary => true
