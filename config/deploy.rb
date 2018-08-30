set :application, 'sul-requests'
set :repo_url, 'https://github.com/sul-dlss/sul-requests.git'

# Default branch is :master
set :branch, 'master'

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
  'config/honeybadger.yml',
  'config/secrets.yml'
)

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push(
  'config/settings',
  'log',
  'tmp/pids',
  'tmp/cache',
  'tmp/sockets',
  'vendor/bundle',
  'public/system'
)

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

# update shared_configs before restarting app
before 'deploy:restart', 'shared_configs:update'


# Sidekiq configuration (run one process with ten threads)
# see sidekiq.yml for concurrency and queue settings
set :sidekiq_processes, 1
# honeybadger_env otherwise defaults to rails_env
set :honeybadger_env, "#{fetch(:stage)}"
