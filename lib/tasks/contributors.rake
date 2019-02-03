
namespace :fromthepage do
  desc "Display all transcriber names and emails"
  task :all_transcribers, [:collection_id] => :environment do |t, args|
    collection_id = args.collection_id
    trans_deeds = DeedType.transcriptions

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
        trans_deeds = DeedType.transcriptions

    collection = Collection.find_by(id: collection_id)
    transcription_deeds = collection.deeds.where(deed_type: trans_deeds)
    note_deeds = collection.deeds.where(deed_type: DeedType::NOTE_ADDED)

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
      puts "New Transcribers: <br> "
      new_transcribers.each do |t|
        puts "<a href='#{Rails.application.routes.url_helpers.url_for({controller: 'user', action: 'profile', user_id: t.id})}'>#{t.display_name}</a>  #{t.email} <br>"
      end
    else
      puts "No new transcribers"
    end

    puts "<br>"

    unless recent_transcriptions.empty?
      puts "Recent Transcriptions: <br>"
      recent_transcriptions.each do |t|
        user_url = Rails.application.routes.url_helpers.url_for({ controller: 'user', action: 'profile', user_id: t.user.id})
        page_url = Rails.application.routes.url_helpers.url_for({ controller: 'display', action: 'display_page', page_id: t.page.id})
        work_url = Rails.application.routes.url_helpers.url_for({ controller: 'display', action: 'read_work', work_id: t.work.id})

        puts "On #{t.created_at}, <a href='#{user_url}'>#{t.user.display_name}</a> (#{t.user.email}) transcribed page <a href='#{page_url}'>#{t.page.title}</a> in the work <a href='#{work_url}'>#{t.work.title}</a>.<br>"
      end
    else
      puts "No recent transcriptions"
    end

    puts "<br>"
    
    unless recent_notes.empty?
      puts "Recent Notes: <br>"
      recent_notes.each do |n|
        user_url = Rails.application.routes.url_helpers.url_for({ controller: 'user', action: 'profile', user_id: n.user.id})
        page_url = Rails.application.routes.url_helpers.url_for({ controller: 'display', action: 'display_page', page_id: n.page.id})
        work_url = Rails.application.routes.url_helpers.url_for({ controller: 'display', action: 'read_work', work_id: n.work.id}) 
        
        puts "On #{n.created_at}, <a href='#{user_url}'>#{n.user.display_name}</a> added a note on page <a href='#{page_url}'>#{n.page.title}</a> in the work <a href='#{work_url}'>#{n.work.title}</a> that read '#{n.note.title}'"
        puts "<br> "
      end
    else
      puts "No recent notes"
    end
  end

end
