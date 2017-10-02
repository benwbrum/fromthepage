namespace :fromthepage do
  desc "current owner stats"
  task :owner_stats => :environment do
      
    AdminMailer.owner_stats.deliver!

  end

end
