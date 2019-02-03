namespace :fromthepage do
  desc "Admin report -- email stats from the previous X hours"
  task :email_stats, [:hours] => :environment do |t,args|
     hours = args.hours
     AdminMailer.email_stats(hours).deliver!
  end

end
