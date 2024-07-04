namespace :fromthepage do
  desc 'send the same view as the contributors tab to all owners for their collections'
  task collection_stats_by_owner: :environment do
    # set variables
    owners = User.where(owner: true).joins(:notification).where(notifications: { owner_stats: true })

    owners.each do |owner|
      if owner.notification.owner_stats
        activity = AdminMailer::OwnerCollectionActivity.build(owner)
        AdminMailer.collection_stats_by_owner(activity).deliver! if activity.collections.present?
      end
    end
  end
end
