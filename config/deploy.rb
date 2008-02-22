set :application, "fromthepage"
set :repository,  "http://svn.fromthepage.com/fromthepage/trunk/diary"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/home/benwbrum/dev/staging/#{application}"

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
# set :scm, :subversion

role :app, "staging.aspengrovefarm.com"
role :web, "staging.aspengrovefarm.com"
role :db,  "staging.aspengrovefarm.com", :primary => true


set :runner, :benwbrum 