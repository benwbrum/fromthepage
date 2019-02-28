namespace :fromthepage do
  desc "current owner account expiration"
  task :owner_stats => :environment do
      
    AdminMailer.owner_stats.deliver!

  end

end
