namespace :fromthepage do
  desc "email stats from the previous X hours"
  task :email_stats, [:hours] => :environment do |t,args|
     print "you specified #{args.hours}\n"
     hours = args.hours
     SystemMailer.email_stats(hours).deliver!
  end

end
