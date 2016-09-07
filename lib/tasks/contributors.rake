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


  desc "Display new transcriber names"
  task :new_transcribers, [:collection_id, :start_date, :end_date] => :environment do |t, args|
    collection_id = args.collection_id
    start_date = args.start_date
    end_date = args.end_date

    trans_deeds = ["page_trans", "page_edit"]

    collection = Collection.find_by(id: collection_id)
    transcription_deeds = collection.deeds.where(deed_type: trans_deeds)

    recent_trans_deeds = transcription_deeds.where("created_at >= ? AND created_at <= ?", start_date, end_date).distinct.pluck(:user_id)
    recent_users = User.where(id: recent_trans_deeds)
    
    older_trans_deeds = transcription_deeds.where("created_at < ?", start_date).distinct.pluck(:user_id)
    older_users = User.where(id: older_trans_deeds)

    new_transcribers = recent_users - older_users

    unless new_transcribers.empty?
      new_transcribers.each do |t|
        puts "#{t.display_name}  #{t.email}"
      end
    else
      puts "No new transcribers"
    end

  end

  desc "Display recent activity in a collection"
  task :recent_activity, [:collection_id, :start_date, :end_date] => :environment do |t, args|
    collection_id = args.collection_id
    start_date = args.start_date
    end_date = args.end_date
    trans_deeds = ["page_trans", "page_edit"]

    collection = Collection.find_by(id: collection_id)
    transcription_deeds = collection.deeds.where(deed_type: trans_deeds)
    note_deeds = collection.deeds.where(deed_type: "note_add")
    
    recent_notes = note_deeds.where("created_at >= ? AND created_at <= ?", start_date, end_date)
    recent_transcriptions = transcription_deeds.where("created_at >= ? AND created_at <= ?", start_date, end_date)
    
    puts "Recent Transcriptions:"
    recent_transcriptions.each do |t|
      puts "Work: #{t.work.title}, Page: #{t.page.title}, User: #{t.user.display_name}, Action: #{t.deed_type}, Date: #{t.created_at}"
    end

    puts "Recent Notes:"
    note_deeds.each do |n|
      puts "Work: #{n.work.title}, User: #{n.user.display_name}, Note: #{n.note.title}"
    end

  end

end
