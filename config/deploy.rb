#set :application, "fromthepage"
#set :repository,  "http://svn.fromthepage.com/fromthepage/trunk/diary"
#
## If you aren't deploying to /u/apps/#{application} on the target
## servers (which is the default), you can specify the actual location
## via the :deploy_to variable:
#set :deploy_to, "/home/benwbrum/dev/staging/#{application}"
#
## If you aren't using Subversion to manage your source code, specify
## your SCM below:
## set :scm, :subversion
#
#role :app, "staging.aspengrovefarm.com"
#role :web, "staging.aspengrovefarm.com"
#role :db,  "staging.aspengrovefarm.com", :primary => true
#
#
#set :runner, :benwbrum 

# updating from http://www.glennfu.com/2008/02/01/deploying-ruby-on-rails-with-capistrano-on-dreamhost/
# The host where people will access my site
set :application, "fromthepage"
#set :user, "my dreamhost username set to access this project"
#set :admin_login, "benwbrum"
set :admin_login, "fromthepage"


# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:

# BWB real is #
set :deploy_to, "/home/#{admin_login}/#{application}"
#set :deploy_to, "/home/#{admin_login}/scratch/staging"

# My DreamHost-assigned server
#set :domain, "#{admin_login}@chalmers.dreamhost.com"
set :domain, "#{admin_login}@66.228.49.247"
role :app, domain
role :web, domain
role :db,  domain, :primary => true

desc "Link shared files"
task :before_symlink do
  run "rm -drf #{release_path}/public/images/working"
#  run "ln -s #{shared_path}/bin #{release_path}/public/images_working"
  run "ln -s #{shared_path}/system/images/working #{release_path}/public/images/"
  run "chmod +w #{release_path}/tmp"
  run "chmod -R g-w #{release_path}"
  
end

set :use_sudo, false
set :checkout, "export"

## I used the handy quick tool to set up an SVN repository on DreamHost and this is where it lives
#set :svn, "/usr/bin/svn"
#set :svn_user, 'benwbrum'
#set :svn_password, 'benwbrum'
#set :repository,
#  Proc.new { "--username #{svn_user} " +
#       "--password #{svn_password} " +
#       "http://svn.fromthepage.com/fromthepage/trunk/diary" }

default_run_options[:pty] = true
set :repository,  "git://github.com/benwbrum/fromthepage.git"
set :scm, "git"

namespace :passenger do
  desc "Restart Application"
  task :restart do
    run "touch #{current_path}/tmp/restart.txt"
  end
end

after :deploy, "passenger:restart"
