require 'bundler/setup'
require 'bundler/capistrano'
require 'dlss/capistrano'

set :stages, %W(development production)
set :default_stage, "development"
set :bundle_flags, "--quiet"

require 'capistrano/ext/multistage'

before "deploy:restart", "deploy:migrate"

set :shared_children, %w(log tmp config/database.yml config/solr.yml)

set :user, "requests" 
set :runner, "requests"

set :destination, "/home/requests"
set :application, "requests-app"
set :deploy_to, "#{destination}/#{application}"

set :ssh_options, {:auth_methods => %w(gssapi-with-mic publickey hostbased), :forward_agent => true}


set :scm, :git
set :deploy_via, :copy # I got 99 problems, but AFS ain't one
set :copy_cache, true
set :copy_exclude, [".git"]
set :use_sudo, false
set :keep_releases, 3


namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end
