namespace :fromthepage do
  desc "transcription stats from the previous 24 hours"
  task :contributor_stats, [:collection_id] => :environment do |t,args|
     collection_id = args.collection_id
     start_date = 1.day.ago
     end_date = DateTime.now.utc
     SystemMailer.contributor_stats(collection_id, start_date, end_date).deliver!
  end

end