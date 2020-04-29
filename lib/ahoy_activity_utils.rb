module AhoyActivityUtils
    def self.rollup_transcribe_for_date(day=1.day.ago)
        # Active users are users who log "transcription-type" deeds on a given day.
        # We only want to track these people for now
        active_users = Deed
        .where(deed_type: DeedType.transcriptions)
        .where("created_at BETWEEN ? AND ?", day.beginning_of_day, day.end_of_day)
        .distinct.pluck(:user_id)
        
        # We make seperate queries for each user on each day to reduce
        # peak memory consumption, since this is a background job
        active_users.each do |user|
        
        # Just for more useful logging
        u = User.find_by(id: user) 
        puts "\t#{u&.login || '[Deleted User]'}"

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
                            puts e
                        else
                            puts "\t\t- Collection: #{activity.collection_id} \t#{activity.minutes} minutes\n"
                        end
                    end
                end
            end
        end
    end
end