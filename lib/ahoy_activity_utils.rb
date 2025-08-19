# frozen_string_literal: true

module AhoyActivityUtils
  def self.rollup_transcribe_for_date(day = 1.day.ago)
    # first, clean up old records for this date
    AhoyActivitySummary.where(date: day.beginning_of_day).delete_all

    # We only want to track these people for now
    active_users = Deed
                   .where('created_at BETWEEN ? AND ?', day.beginning_of_day, day.end_of_day)
                   .distinct.pluck(:user_id)

    # We make seperate queries for each user on each day to reduce
    # peak memory consumption, since this is a background job
    active_users.each do |user|
      # Just for more useful logging
      puts "\tUser ID: #{user}"

      # We figure if you are logged in and doing stuff it counts as volunteer time
      # This could be expanded or resctricted
      events = Ahoy::Event
               .where(user_id: user)
               .where('time BETWEEN ? AND ?', day.beginning_of_day, day.end_of_day)
               .select(:id, :user_id, :time, :name, :properties)

      next if events.empty?

      # We group by collection first, so we can sort and sum the timestamps
      events.group_by { |e| e.properties['collection_id'] }.each do |cid, event|
        timestamps = event.map { |e| [ e[:time], e[:name] ] }

        minutes = total_contiguous_seconds(timestamps) / 60

        next unless minutes.positive?

        begin
          activity = AhoyActivitySummary.create(
            {
              date: day.beginning_of_day,
              user_id: user,
              collection_id: cid,
              activity: 'transcribe',
              minutes: minutes
            }
          )
        rescue ActiveRecord::RecordNotUnique => e
          puts e
        else
          puts "\t\t- Collection: #{activity.collection_id} \t#{activity.minutes} minutes\n"
        end
      end
    end

    latest_ahoy_activity_summary = AhoyActivitySummary.order(date: :desc).first
    keep_after_date = [ AhoyActivitySummary::KEEP_AFTER.ago.to_date, latest_ahoy_activity_summary.date.yesterday ].min

    exclude_actions = AhoyActivitySummary::WEEKLY_TRIAL_COHORT_TARGET_ACTIONS +
                      AhoyActivitySummary::WEEKLY_TRANSCRIBER_COHORT_TARGET_ACTIONS


    Ahoy::Event.where('time < ?', keep_after_date)
                .where.not(name: exclude_actions)
                .in_batches(of: 1_000)
                .delete_all

    Visit.left_joins(:ahoy_events)
                .where('started_at < ?', keep_after_date)
                .where(ahoy_events: { id: nil })
                .in_batches(of: 1_000)
                .delete_all
  end

  def self.total_contiguous_seconds(times_and_names, tolerance = 90.minutes)
    total_seconds = 0
    from_time = nil

    grouped_events = times_and_names.group_by { |e| e[0] }
    times=grouped_events.keys.sort

    for time in times.sort do
      time_diff = from_time.nil? ? 0 : (time - from_time).round
      if time_diff < tolerance && time_diff > 0
        total_seconds += time_diff
      else
        # if less than tolerance and there's a discontinuity
        # is the first event a save
        # use save transcription or assign categories for indicating a save since they happen at the same event time
        events = grouped_events[time]
        names = events.map { |e| e[1] }
        if names.include?('transcribe#assign_categories') || names.include?('transcribe#save_transcription')
          # if the first event was a save, they were transcribing and we need to pad
          # just pad by adding 20 minutes
          # in the future we may want to pad based on project type text: 20 minutes, spreadsheet: 90 minutes, field: 5 minutes
          total_seconds += 20*60
        end
      end
      from_time = time
    end
    total_seconds
  end
end
