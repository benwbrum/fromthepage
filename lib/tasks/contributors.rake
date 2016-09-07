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
  task :new_transcribers, [:collection_id, :date] => :environment do |t, args|
    collection_id = args.collection_id
    date_condition = args.date
    trans_deeds = ["page_trans", "page_edit"]

    collection = Collection.find_by(id: collection_id)
    transcription_deeds = collection.deeds.where(deed_type: trans_deeds)

    recent_trans_deeds = transcription_deeds.where("created_at <= ?", date_condition).distinct.pluck(:user_id)
    recent_users = User.where(id: recent_trans_deeds)
    
    older_trans_deeds = transcription_deeds.where("created_at > ?", date_condition).distinct.pluck(:user_id)
    older_users = User.where(id: older_trans_deeds)

    new_transcribers = older_users - recent_users

    unless new_transcribers.empty?
      new_transcribers.each do |t|
        puts "#{t.display_name}  #{t.email}"
      end
    else
      puts "No new transcribers"
    end

  end

  desc "Display recent activity in a collection"
  task :recent_activity, [:collection_id, :date] => :environment do |t, args|
    collection_id = args.collection_id
    date_condition = args.date
    trans_deeds = ["page_trans", "page_edit"]

    collection = Collection.find_by(id: collection_id)
    transcription_deeds = collection.deeds.where(deed_type: trans_deeds)

    note_deeds = collection.deeds.where("deed_type = ? AND created_at >= ?", "note_add", date_condition)
    recent_transcriptions = transcription_deeds.where("created_at >= ?", date_condition)
    
    puts "Recent Transcriptions:"
    recent_transcriptions.each do |t|
      puts "Work: #{t.work.title}, Page: #{t.page.title}, User: #{t.user.display_name}"
    end

    puts "Recent Notes:"
    note_deeds.each do |n|
      puts "Work: #{n.work.title}, User: #{n.user.display_name}, Note: #{n.note.title}"
    end

  end

end
