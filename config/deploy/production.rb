set :rails_env, "production"
set :deployment_host, "sulwebapp5"
set :repository,  "."
set :bundle_without, [:deployment]

role :web, deployment_host
role :app, deployment_host
role :db,  deployment_host, :primary => true
