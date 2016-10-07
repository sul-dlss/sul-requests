# config valid only for current version of Capistrano
lock '3.6.0'

set :application, 'sul-requests'
set :repo_url, 'https://github.com/sul-dlss/sul-requests.git'
set :deploy_host, "requests-#{fetch(:stage)}.stanford.edu"
set :user, 'requests'

# Default branch is :master
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/opt/app/#{fetch(:user)}/#{fetch(:user)}"

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
  'config/secrets.yml',
  'public/.htaccess'
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

server fetch(:deploy_host), user: fetch(:user), roles: %w(web db app)

Capistrano::OneTimeKey.generate_one_time_key!

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

set :honeybadger_env, fetch(:stage)
