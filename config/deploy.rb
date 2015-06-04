# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'sul-requests'
set :repo_url, 'https://github.com/sul-dlss/sul-requests.git'
set :deploy_host, ask("Server", 'e.g. hostname with no ".stanford.edu" or server node designator')
ask :user, proc { `whoami`.chomp }.call

# Default branch is :master
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/opt/app/#{fetch(:user)}/#{fetch(:user)}"

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/initializers/squash.rb')

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('config/settings',
                                               'log',
                                               'tmp/pids',
                                               'tmp/cache',
                                               'tmp/sockets',
                                               'vendor/bundle',
                                               'public/system')

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

before 'deploy:publishing', 'squash:write_revision'

namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end
end
