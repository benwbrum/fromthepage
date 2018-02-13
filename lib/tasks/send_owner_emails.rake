namespace :fromthepage do
  desc "transcription stats for all owners and collections"
  task :collection_stats_by_owner => :environment do

    OWNER_EMAIL_BLACKLIST = []

    #set variables
    owners = User.where(owner: true).joins(:notification).where(notifications: {owner_stats: true})
    start_date = 1.day.ago
    end_date = DateTime.now.utc
    owners.each do |owner|
      unless OWNER_EMAIL_BLACKLIST.include?(owner.email)
        collections = owner.all_owner_collections.joins(:deeds).where(deeds: {created_at: start_date..end_date})
        unless collections.blank?
          AdminMailer.collection_stats_by_owner(owner, start_date, end_date).deliver!
        end
      end
    end
  end

end