set :application, 'sul-requests'
set :repo_url, 'https://github.com/sul-dlss/sul-requests.git'

# Default branch is :master so we need to update to main
if ENV['DEPLOY']
  set :branch, 'main'
else
  ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call
end

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/opt/app/requests/requests'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
set :log_level, :info

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, fetch(:linked_files, []).push(
  'config/database.yml',
  'config/honeybadger.yml'
)

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push(
  'config/settings',
  'log',
  'tmp/pids',
  'tmp/cache',
  'tmp/sockets',
  'tmp/state',
  'vendor/bundle',
  'public/system'
)

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

# update shared_configs before restarting app
before 'deploy:restart', 'shared_configs:update'

# honeybadger_env otherwise defaults to rails_env
set :honeybadger_env, "#{fetch(:stage)}"

namespace :deploy do
  after :restart, :restart_sidekiq do
    on roles(:app) do
      sudo :systemctl, "restart", "sidekiq-*", raise_on_non_zero_exit: false
    end
  end
end
