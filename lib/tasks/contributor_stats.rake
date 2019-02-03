namespace :fromthepage do
  desc "DEPRACATED -- use collection_stats_by_owner instead"
  task :contributor_stats, [:collection_id, :email] => :environment do |t,args|
      collection_id = args.collection_id
      email = []
      email << args.email
      other = args.extras
      unless other.empty?
        other.each do |e|
          email << e
        end
      end
      start_date = 1.day.ago
      end_date = DateTime.now.utc
      AdminMailer.contributor_stats(collection_id, start_date, end_date, email).deliver!
  end

end