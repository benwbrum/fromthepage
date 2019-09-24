namespace :fromthepage do
  desc "nightly collection activity (new works and new notes) sent to users"
  task :nightly_user_activity => :environment do
    
    # Work_Added Deeds within the last 24 Hours
    recently_added_works = Deed.past_day
      .where({deed_type: DeedType::WORK_ADDED})
    # Collections that have recently had works added to them
    new_works_collections = Collection.joins(:deeds)
      .merge(recently_added_works)
      .distinct
    # All users related to these criteria
    all_collection_scribes = User.joins(:deeds)
      .where({deeds: {collection_id: new_works_collections.ids}})
      .distinct
    
    # Note_Added Deeds within the last 24 Hours
    recently_added_notes = Deed.past_day
      .where({deed_type: DeedType::NOTE_ADDED})
    # Pages that have recently had notes added to them
    new_notes_pages = Page.joins(:deeds)
      .merge(recently_added_notes)
      .distinct
    # All users related to these criteria
    all_page_scribes = User.joins(:deeds)
      .where({deeds: {page_id: new_notes_pages.ids}})
      .distinct
    
    # All users that should get an email (union of the above)
    all_users = all_collection_scribes | all_page_scribes

    if SMTP_ENABLED
      all_users.each do |user|
        begin
          user_activity = UserMailer::Activity.build(user)

          if user_activity.has_contributions?
            puts "There was activity on #{user.display_name}\'s previous work in the past 24 hours"
            UserMailer.nightly_user_activity(user_activity).deliver! if user.notification.user_activity
          end
        rescue StandardError => e
          print "SMTP Failed: Exception: #{e.message} \n"
        end
      end
    end # end SMTP
  end

end
