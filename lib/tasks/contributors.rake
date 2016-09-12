namespace :fromthepage do
  desc "Display all transcriber names and emails"
  task :all_transcribers, [:collection_id] => :environment do |t, args|
    collection_id = args.collection_id
    trans_deeds = ["page_trans", "page_edit"]

    collection = Collection.find_by(id: collection_id)
    transcription_deeds = collection.deeds.where(deed_type: trans_deeds)
    user_deeds = transcription_deeds.distinct.pluck(:user_id)
    all_transcribers = User.where(id: user_deeds)

    all_transcribers.each do |t|
      puts "#{t.display_name} <#{t.email}>, "
    end

  end

  desc "Display all recent activity for a collection"
  task :recent_activity, [:collection_id] => :environment do |t, args|
    collection_id = args.collection_id
        trans_deeds = ["page_trans", "page_edit"]

    collection = Collection.find_by(id: collection_id)
    transcription_deeds = collection.deeds.where(deed_type: trans_deeds)
    note_deeds = collection.deeds.where(deed_type: "note_add")
    
    # notes and transcriptions created during the time frame
    recent_notes = note_deeds.where("created_at >= ?", 1.day.ago)
    recent_transcriptions = transcription_deeds.where("created_at >= ?", 1.day.ago)
    
    #find recent users
    recent_trans_deeds = recent_transcriptions.distinct.pluck(:user_id)
    recent_users = User.where(id: recent_trans_deeds)
    
    #find older users (from before time frame)
    older_trans_deeds = transcription_deeds.where("created_at < ?", 1.day.ago).distinct.pluck(:user_id)
    older_users = User.where(id: older_trans_deeds)

    #find the difference between the recent and older lists
    new_transcribers = recent_users - older_users

    unless new_transcribers.empty?
      puts "New Transcribers"
      new_transcribers.each do |t|
        puts "#{t.display_name}  #{t.email}"
      end
    else
      puts "No new transcribers"
    end

    puts " "

    unless recent_transcriptions.empty?
      puts "Recent Transcriptions:"
      recent_transcriptions.each do |t|
        puts "Work: #{t.work.title}, User: #{t.user.display_name}, User Email: #{t.user.email}, Page: #{t.page.title}, Date: #{t.created_at}"
      end
    else
      puts "No recent transcriptions"
    end

    puts " "
    
    unless recent_notes.empty?
      puts "Recent Notes:"
      recent_notes.each do |n|
        puts "Work: #{n.work.title}, User: #{n.user.display_name}, User Email: #{n.user.email}, Note: #{n.note.title}, Date: #{n.created_at}"
      end
    else
      puts "No recent notes"
    end
  end

end
