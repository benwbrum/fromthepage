# config valid only for Capistrano 3.1
# lock '3.4.1'

set :application, 'fromthepage'
set :repo_url, 'git@github.com:benwbrum/fromthepage.git'

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app
set :deploy_to, '/home/fromthepage/deployment'

# Default value for :scm is :git
# set :scm, :git
set :branch, 'ui-design'
# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, %w[.env config.ru config/database.yml config/environments/production.rb config/initializers/01fromthepage.rb config/initializers/rack_attack.rb config/initializers/omniauth.rb config/newrelic.yml public/robots.txt]

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}
set :linked_dirs, ['log', 'public/images/working', 'public/uploads', 'tmp', 'public/images/uploaded', 'public/images/fordham', 'public/images/zebrapedia', 'public/text']

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 20

set :assets_roles, [:web, :app]

namespace :deploy do
  desc 'Install Node dependencies'
  task :npm_install do
    on roles(:app) do
      within release_path do
        execute :npm, 'ci', '--omit=dev'
      end
    end
  end

  after :updated, :npm_install

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart

  after :restart, :restart_solid_queue

  desc 'Restart Solid Queue service'
  task :restart_solid_queue do
    on roles(:app) do
      execute :sudo, :systemctl, 'restart solid_queue'
    end
  end

  after :restart_solid_queue, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

  desc 'Check that we can access everything'
  task :check_write_permissions do
    on roles(:all) do |host|
      if test("[ -w #{fetch(:deploy_to)} ]")
        info "#{fetch(:deploy_to)} is writable on #{host}"
      else
        error "#{fetch(:deploy_to)} is not writable on #{host}"
      end
    end
  end
end
