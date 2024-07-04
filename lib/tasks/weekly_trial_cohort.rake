namespace :fromthepage do
  desc 'weekly trial cohort'
  task weekly_trial_cohort: :environment do
    # generate a csv file of users who signed up in the last week and write it out to a temporary file
    TARGET_ACTIONS = ['static#landing_page', 'registrations#new_trial', 'registrations#create', 'collection#create']
    TEMP_FILE = '/tmp/conversion_cohorts.csv'
    week_cohorts = []
    current_day = Date.new(2023, 2, 12)
    while current_day + 1.week < Time.zone.today
      week_cohorts << current_day
      current_day += 1.week
    end

    f = File.open(TEMP_FILE, 'w+')
    f.print("Start Date\tLanding Pages\tLanding to Trial %\tNew Trial Views\tNew Trial to Account %\tTrial Creations\tAccout to Collection %\tCollection Creations\tCollection Created %\tHave Collections\tUploaded Work %\tWork Upload\tTranscribed Page %\tPage Transcribed\tMulti-Contributor %\tMultiple Contributors\tAccount Created to Page Transcribed %\tAccount Created to Multi Contributor %\tAccount Creation to First Page Transcribed (median minutes)\tMinutes To First Page By Others (median)\n")
    week_cohorts.each do |start_day|
      end_day = start_day + 1.week
      f.print("#{start_day}\t")
      previous_visits = nil
      previous_actions = nil
      registrations_create_count = nil
      TARGET_ACTIONS.each do |action|
        if previous_visits
          visits = Ahoy::Event.where(time: start_day..end_day, name: action, visit_id: previous_visits).pluck(:visit_id).uniq
        else
          visits = Ahoy::Event.where(time: start_day..end_day, name: action).pluck(:visit_id).uniq

        end
        action_count = visits.count
        previous_visits = visits

        if previous_actions
          pct = action_count.fdivprevious_actions.round(4)
          f.print("#{pct}\t")
        end
        f.print("#{action_count}\t")

        # we'll need this later for TTFPT
        registrations_create_count = action_count if action == 'registrations#create'
        previous_actions = action_count
      end

      # additional statistics require non-Ahoy data
      collection_users = User.where(id: Visit.where(id: previous_visits).select(:user_id))
      ids_with_collections = collection_users.select { |u| u.collections.present? }.map(&:id)
      action_count = ids_with_collections.count
      pct = action_count.fdivprevious_actions.round(4)
      f.print("#{pct}\t")
      f.print("#{action_count}\t")
      previous_actions = action_count

      users_with_collections = User.find(ids_with_collections)
      ids_with_pages = users_with_collections.select { |u| u.owner_works.present? }.map(&:id)
      action_count = ids_with_pages.count
      pct = action_count.fdivprevious_actions.round(4)
      f.print("#{pct}\t")
      f.print("#{action_count}\t")
      previous_actions = action_count

      users_with_pages = User.find(ids_with_pages)
      ids_with_activity = users_with_pages.select do |u|
        u.owner_works.detect do |w|
          (w.work_statistic.line_count || 0) > 0
        end
      end.map(&:id)
      action_count = ids_with_activity.count
      users_with_pages_transcribed = action_count
      pct = action_count.fdivprevious_actions.round(4)
      f.print("#{pct}\t")
      f.print("#{action_count}\t")
      previous_actions = action_count

      users_with_activity = User.find(ids_with_activity)
      ids_with_multiple_contributors = users_with_activity.select do |u|
        u.owned_collections.detect do |c|
          c.deeds.pluck(:user_id).uniq.count > 1
        end
      end.map(&:id)
      action_count = ids_with_multiple_contributors.count
      users_with_pages_transcribed_by_others = action_count
      pct = action_count.fdivprevious_actions.round(4)
      f.print("#{pct}\t")
      f.print("#{action_count}\t")
      previous_actions = action_count

      # Account Created to Page Transcribed %
      pct = users_with_pages_transcribed.fdivregistrations_create_count.round(4)
      f.print("#{pct}\t")

      # Account Created to Multi Contributor %
      pct = users_with_pages_transcribed_by_others.fdivregistrations_create_count.round(4)
      f.print("#{pct}\t")

      # Account Creation to First Page Transcribed (median)
      users_with_pages_transcribed = User.find(ids_with_activity)
      durations_to_first_transcription = []
      # for each user, find out when their account was created (user.creation_date?) and find the first page transcribed deed
      users_with_pages_transcribed.each do |user|
        first_edit_dates = user.collections.map { |c| c.deeds.where(deed_type: DeedType.collection_edits).minimum(:created_at) }
        first_edit_date = first_edit_dates.compact.sort.first
        durations_to_first_transcription << (first_edit_date - user.created_at)
      end
      median_ttfpt = durations_to_first_transcription.sort[durations_to_first_transcription.count / 2]
      if median_ttfpt
        f.print("#{median_ttfpt / 60}\t")
      else
        f.print("\t")
      end

      # Account Creation to First Page Transcribed By Other(median)
      users_with_pages_transcribed_by_others = User.find(ids_with_multiple_contributors)
      durations_to_first_transcription_by_others = []
      # for each user, find out when their account was created (user.creation_date?) and find the first page transcribed deed
      users_with_pages_transcribed_by_others.each do |user|
        first_edit_dates = user.collections.map do |c|
          c.deeds.where(deed_type: DeedType.collection_edits).where.not(user_id: user.id).minimum(:created_at)
        end
        first_edit_date = first_edit_dates.compact.sort.first
        durations_to_first_transcription_by_others << (first_edit_date - user.created_at)
      end
      median_ttfpt = durations_to_first_transcription_by_others.sort[durations_to_first_transcription_by_others.count / 2]
      if median_ttfpt
        f.print("#{median_ttfpt / 60}\t")
      else
        f.print("\t")
      end

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
