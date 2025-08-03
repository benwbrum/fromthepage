namespace :fromthepage do
  desc "send the same view as the contributors tab to all owners for their collections"
  task :collection_stats_by_owner => :environment do

    #set variables
    owners = User.where(owner: true).joins(:notification).where(notifications: {owner_stats: true})

    owners.each do |owner|
	    if owner.notification.owner_stats
        activity = AdminMailer::OwnerCollectionActivity.build(owner)
        if activity.has_activity?
          begin
            AdminMailer.collection_stats_by_owner(activity).deliver!
          rescue Postmark::InactiveRecipientError => e
            puts "An exception was raised while trying to notify: #{e.message}"
          end
        end
      end
    end
  end

end
