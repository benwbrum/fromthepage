namespace :fromthepage do
  desc "weekly transcriber cohort"
  task :weekly_transcriber_cohort => :environment do
    # generate a csv file of users who signed up in the last week and write it out to a temporary file
    TRANSCRIBER_TARGET_ACTIONS = ['static#landing_page', 'registrations#new', 'registrations#create', 'transcribe#display_page', 'transcribe#save_transcription']
    TRANSCRIBER_TEMP_FILE='/tmp/transcriber_conversion_cohorts.csv'
    week_cohorts=[]
    current_day=Date.new(2023,2,12)
    while current_day+1.week < Date.today
      week_cohorts << current_day
      current_day=current_day+1.week
    end

    f = File.open(TRANSCRIBER_TEMP_FILE, 'w+')
    f.print("Start Date\tLanding Pages\tLanding to Signup Screen %\tSignup Screen Views\tSignup Screen to Account %\tAccount Creations\tAccount to Transcribe Screen %\tTranscribe Screen\tPage Saved %\tSave Transcription\tAccount Created to Page Transcribed %\tAccount Creation to First Page Transcribed (median minutes)\n")
    action_count = nil
    week_cohorts.each do |start_day|
      end_day = start_day+1.week
      f.print("#{start_day}\t")
      previous_visits = nil
      previous_actions=nil
      registrations_create_count = nil
      TRANSCRIBER_TARGET_ACTIONS.each do |action|
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
 
        # we'll need this later for TTFPT
        if action == 'registrations#create'
          registrations_create_count = action_count
        end
        previous_actions=action_count
      end

      # Account Created to Page Transcribed %
      pct = (action_count.to_f/registrations_create_count).round(4)
      f.print("#{pct}\t")


      # Account Creation to First Page Transcribed (median)

      user_ids_from_page_transcribed_visits = Visit.where(id: previous_visits).pluck(:user_id).uniq
      users_with_pages_transcribed = User.where(id: user_ids_from_page_transcribed_visits)
      durations_to_first_transcription = []
      # for each user, find out when their account was created (user.creation_date?) and find the first page transcribed deed
      users_with_pages_transcribed.each do |user|
        first_contribution_date = user.deeds.where(deed_type: DeedType.collection_edits).minimum(:created_at) 
        durations_to_first_transcription << first_contribution_date - user.created_at unless first_contribution_date.nil?
      end
      median_ttfpt = durations_to_first_transcription.sort[durations_to_first_transcription.count/2]
      if median_ttfpt
        f.print("#{median_ttfpt/60}\t")
      else
        f.print("\t")
      end


      f.print("\n")
    end
    f.close

    # send the file to the admin
    if SMTP_ENABLED
      begin
        AdminMailer.weekly_transcriber_cohort(TRANSCRIBER_TEMP_FILE).deliver!
      rescue StandardError => e
        print "SMTP Failed: Exception: #{e.message} \n"
      end
    end

  end
end