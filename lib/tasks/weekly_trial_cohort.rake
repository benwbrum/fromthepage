namespace :fromthepage do
  desc "weekly trial cohort"
  task :weekly_trial_cohort => :environment do
    # generate a csv file of users who signed up in the last week and write it out to a temporary file
    TARGET_ACTIONS = ['static#landing_page', 'registrations#new_trial', 'registrations#create', 'collection#create']
    TEMP_FILE='/tmp/conversion_cohorts.csv'
    week_cohorts=[]
    current_day=Date.new(2023,2,12)
    while current_day+1.week < Date.today
      week_cohorts << current_day
      current_day=current_day+1.week
    end

    f = File.open(TEMP_FILE, 'w+')
    f.print("Start Date\tLanding Pages\tLanding to Trial %\tNew Trial Views\tNew Trial to Account %\tTrial Creations\tAccout to Collection %\tCollection Creations\tCollection Created %\tHave Collections\tUploaded Work %\tWork Upload\tTranscribed Page %\tPage Transcribed\tMulti-Contributor %\tMultiple Contributors\n")
    week_cohorts.each do |start_day|
      end_day = start_day+1.week
      f.print("#{start_day}\t")
      previous_visits = nil
      previous_actions=nil
      TARGET_ACTIONS.each do |action|
        if previous_visits
          visits = Ahoy::Event.where(time: start_day..end_day, name: action, visit_id: previous_visits).pluck(:visit_id).uniq
          action_count = visits.count
          previous_visits = visits
        else
          visits = Ahoy::Event.where(time: start_day..end_day, name: action).pluck(:visit_id).uniq
          action_count = visits.count
          previous_visits = visits

        end

        if previous_actions
          pct = (action_count.to_f/previous_actions).round(4)
          f.print("#{pct}\t")
        end
        f.print("#{action_count}\t")
        previous_actions=action_count
      end

      # additional statistics require non-Ahoy data
      collection_users = User.where(id: Visit.where(id: previous_visits).pluck(:user_id))
      ids_with_collections = collection_users.select{|u| u.collections.present? }.map{|u| u.id}
      action_count = ids_with_collections.count
      pct = (action_count.to_f/previous_actions).round(4)
      f.print("#{pct}\t")
      f.print("#{action_count}\t")
      previous_actions=action_count

      users_with_collections = User.find(ids_with_collections)
      ids_with_pages = users_with_collections.select{|u| u.owner_works.present? }.map{|u| u.id}
      action_count = ids_with_pages.count
      pct = (action_count.to_f/previous_actions).round(4)
      f.print("#{pct}\t")
      f.print("#{action_count}\t")
      previous_actions=action_count

      users_with_pages = User.find(ids_with_pages)
      ids_with_activity = users_with_pages.select{|u| u.owner_works.detect{|w| (w.work_statistic.line_count||0) > 0} }.map{|u| u.id}
      action_count = ids_with_activity.count
      pct = (action_count.to_f/previous_actions).round(4)
      f.print("#{pct}\t")
      f.print("#{action_count}\t")
      previous_actions=action_count


      users_with_activity = User.find(ids_with_activity)
      ids_with_multiple_contributors = users_with_activity.select{|u| u.owned_collections.detect{|c| c.deeds.pluck(:user_id).uniq > 1} }.map{|u| u.id}
      action_count = ids_with_multiple_contributors.count
      pct = (action_count.to_f/previous_actions).round(4)
      f.print("#{pct}\t")
      f.print("#{action_count}\t")
      previous_actions=action_count


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