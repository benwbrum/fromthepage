namespace :fromthepage do
  desc "Daily Task to Rollup Ahoy Events into Transcribe minutes by Date, User, and Collection"
  task ahoy_activity_rollup: :environment do
    rollup_transcribe_for_date()
  end

  desc "An ad-hoc task to populate the ahoy rollup for historical data"
  task ahoy_rollup_crawl: :environment do

    ## Figure out how long we need to count back
    first_ahoy_event = Date.new(2017, 10, 22).beginning_of_day
    days = ( (Time.now.beginning_of_day - first_ahoy_event) / 60 / 60 / 24).to_i
    
    
    # Count back from yesterday into the past
    (1..days).each do |n|
      date = n.days.ago

      print "\n---Ahoy Rollup #{date.strftime("%Y-%m-%d")}\n"

      # Perform the rollup for the day
      rollup_transcribe_for_date(date)
    end
  end

  def rollup_transcribe_for_date(day=1.day.ago)
      # Active users are users who log "transcription-type" deeds on a given day.
      # We only want to track these people for now
      active_users = Deed
        .where(deed_type: DeedType.transcriptions)
        .where("created_at BETWEEN ? AND ?", day.beginning_of_day, day.end_of_day)
        .distinct.pluck(:user_id)
      
      # We make seperate queries for each user on each day to reduce
      # peak memory consumption, since this is a background job
      active_users.each do |user|
        u = User.find_by(id: user) # just formore useful logging
        # We Define transcribe events as any even on the transcribe controller
        # This could be expanded or resctricted
        events = Ahoy::Event
          .where(user_id: user)
          .where("name LIKE 'transcribe#%'")
          .where("time BETWEEN ? AND ?", day.beginning_of_day, day.end_of_day)
          .select(:id, :user_id, :time, :properties)

        unless events.empty?
          # We group by collection first, so we can sort and sum the timestamps
          events
            .group_by { |e| e.properties["collection_id"] }
            .each do |cid, event|

                timestamps = event.map{|e| e[:time] }
                
                minutes = UserCollectionTime.total_contiguous_seconds(timestamps) / 60
                
                unless minutes <= 0
                  begin 
                    activity = AhoyActivitySummary.create({
                      date: day.beginning_of_day,
                      user_id: user,
                      collection_id: cid,
                      activity: 'transcribe',
                      minutes: minutes
                    })
                  rescue ActiveRecord::RecordNotUnique => e
                    print e
                  else
                    print "#{u&.login || '[Deleted User]'} | Collection: #{activity.collection_id} | #{activity.minutes} minutes"
                  end
                end
            end
          end
      end
    end
end
