namespace :fromthepage do
  desc "transcription stats for all owners and collections"
  task :collection_stats_by_owner => :environment do

    OWNER_EMAIL_BLACKLIST = []

    #set variables
    owners = User.where(owner: true).joins(:notification).where(notifications: {owner_stats: true})
    start_date = 1.day.ago
    end_date = DateTime.now.utc
    owners.each do |owner|
      unless OWNER_EMAIL_BLACKLIST.include?(owner.email)
        collections = owner.all_owner_collections.joins(:deeds).where(deeds: {created_at: start_date..end_date})
        unless collections.blank?
          AdminMailer.collection_stats_by_owner(owner, start_date, end_date).deliver!
        end
      end
    end
  end

  desc "monthly owner email wrap ups"
  task :monthly_owner_wrapup => :environment do
    owners = User.where(owner: true).where.not(account_type: [nil, 'Trial'])
    if SMTP_ENABLED
      owners.each do |owner|
        puts owner.display_name
        begin
          UserMailer.monthly_owner_wrapup(owner).deliver!
        rescue StandardError => e
          print "SMTP Failed: Exception: #{e.message} \n"
        end
      end
    end
  end

  desc "project is 100 percent transcribed"
  task :project_complete, [:collection_id] => :environment do |t, args|
    id = args.collection_id
    project = Collection.find_by(id: id)
    puts "INFO: #{project.title} is complete"
    if SMTP_ENABLED
      begin
        UserMailer.project_complete(project).deliver!
      rescue StandardError => e
        print "SMTP Failed: Exception: #{e.message} \n"
      end
    end

  end


end
