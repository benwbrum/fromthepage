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
set :user, "my dreamhost username set to access this project"
set :admin_login, "fromthepage" #bpoc user

set :repository,  "http://svn.fromthepage.com/fromthepage/trunk/diary"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:

set :deploy_to, "/home/#{admin_login}/#{application}"

set :domain, "#{admin_login}@fromthepage.bpoc.org" #bpoc user
role :app, domain
role :web, domain
role :db,  domain, :primary => true

desc "Link shared files"
task :before_symlink do
  run "rm -drf #{release_path}/public/images/working"
  run "ln -s #{shared_path}/bin #{release_path}/public/images_working"
  run "ln -s #{shared_path}/system/images/working #{release_path}/public/images/"
  run "chmod +w #{release_path}/tmp"
  run "chmod -R g-w #{release_path}"
  
end

set :use_sudo, false
set :checkout, "export"


default_run_options[:pty] = true
set :repository,  "git://github.com/klauberpilot/fromthepage.git"
set :scm, "git"


desc "Restarting after deployment"
task :after_deploy, :roles => [:app, :db, :web] do
  run "touch #{deploy_to}/current/public/dispatch.fcgi" 

  run "sed 's/# ENV\\[/ENV\\[/g' #{deploy_to}/current/config/environment.rb > #{deploy_to}/current/config/environment.temp"
  run "mv #{deploy_to}/current/config/environment.temp #{deploy_to}/current/config/environment.rb"
  run "cp #{deploy_to}/current/public/.htaccess.prod #{deploy_to}/current/public/.htaccess"
end

desc "Restarting after rollback"
task :after_rollback, :roles => [:app, :db, :web] do
  run "touch #{deploy_to}/current/public/dispatch.fcgi"
end
