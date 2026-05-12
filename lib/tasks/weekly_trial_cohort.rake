namespace :fromthepage do
  desc 'weekly trial cohort'
  task weekly_trial_cohort: :environment do
    # generate a csv file of users who signed up in the last week and write it out to a temporary file
    target_actions = AhoyActivitySummary::WEEKLY_TRIAL_COHORT_TARGET_ACTIONS
    TEMP_FILE='/tmp/conversion_cohorts.csv'
    week_cohorts=[]
    current_day=Date.new(2023, 2, 12)
    while current_day+1.week <= Date.today
      week_cohorts << current_day
      current_day=current_day+1.week
    end

    f = File.open(TEMP_FILE, 'w+')
    f.print("Start Date\tTrial Creations\tWork Upload\tPage Transcribed\tAI Draft Used\n")
    week_cohorts.each do |start_day|
      end_day = start_day+1.week
      f.print("#{start_day}\t")
      previous_visits = nil
      registrations_visits = nil
      target_actions.each do |action|
        if previous_visits
          visits = Ahoy::Event.where(time: start_day..end_day, name: action, visit_id: previous_visits).pluck(:visit_id).uniq
        else
          visits = Ahoy::Event.where(time: start_day..end_day, name: action).pluck(:visit_id).uniq
        end
        previous_visits = visits

        if action == 'registrations#create'
          f.print("#{visits.count}\t")
          registrations_visits = visits
        end
      end

      # additional statistics require non-Ahoy data
      collection_users = User.where(id: Visit.where(id: previous_visits).pluck(:user_id))
      ids_with_collections = collection_users.select { |u| u.collections.present? }.map { |u| u.id }

      users_with_collections = User.find(ids_with_collections)
      ids_with_pages = users_with_collections.select { |u| u.owner_works.present? }.map { |u| u.id }

      users_with_pages = User.find(ids_with_pages)
      ids_with_activity = users_with_pages.select { |u| u.owner_works.detect { |w| (w.work_statistic.line_count||0) > 0 } }.map { |u| u.id }
      f.print("#{ids_with_activity.count}\t")

      users_with_activity = User.find(ids_with_activity)
      ids_with_multiple_contributors = users_with_activity.select { |u| u.owned_collections.detect { |c| c.deeds.pluck(:user_id).uniq.count > 1 } }.map { |u| u.id }
      f.print("#{ids_with_multiple_contributors.count}\t")

      trial_user_ids = Visit.where(id: registrations_visits).pluck(:user_id).compact
      ai_draft_count = DocumentUpload.where(user_id: trial_user_ids, generate_ai_draft: true)
                                     .where(created_at: start_day..end_day)
                                     .pluck(:user_id).uniq.count
      f.print("#{ai_draft_count}\t")

      f.print("\n")
    end
    f.close

    # send the file to the admin
    if SMTP_ENABLED
      begin
        AdminMailer.weekly_trial_cohort(TEMP_FILE).deliver!
      rescue StandardError => e
        print "SMTP Failed: Exception: #{e.message} \n"
      end
    end
  end
end
