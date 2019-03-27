namespace :fromthepage do
  desc "send the same view as the contributors tab to all owners for their collections"
  task :collection_stats_by_owner => :environment do

    OWNER_EMAIL_BLACKLIST = []

    #set variables
    owners = User.where(owner: true).joins(:notification).where(notifications: {owner_stats: true})

    owners.each do |owner|
      unless OWNER_EMAIL_BLACKLIST.include?(owner.email)
        activity = AdminMailer::OwnerCollectionActivity.build(owner)
        unless activity.collections.blank?
          AdminMailer.collection_stats_by_owner(activity).deliver!
        end
      end
    end
  end

end