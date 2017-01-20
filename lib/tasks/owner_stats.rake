namespace :fromthepage do
  desc "current owner stats"
  task :owner_stats, [:email] => :environment do |t,args|
      email = []
      email << args.email
      other = args.extras
      unless other.empty?
        other.each do |e|
          email << e
        end
      end
     AdminMailer.owner_stats(email).deliver!

  end

end
