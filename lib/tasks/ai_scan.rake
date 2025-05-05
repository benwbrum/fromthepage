namespace :fromthepage do
  desc "looks for users who have page_trans deeds with little time between them "
  task detect_frequent_contributions: :environment do
    # only look at the last 24 hours
    start_time = 24.hours.ago
    end_time = Time.now
    # find users who have page_trans deeds in the last 24 hours

    users = User.joins(:deeds).where('deeds.created_at BETWEEN ? AND ?', start_time, end_time).where('deeds.deed_type = ?', DeedType::PAGE_TRANSCRIPTION).distinct
    users.each do |user|
      # find the time between each of the page_trans deeds
      # why does this return no deeds?
      deeds = user.deeds.where(created_at: [start_time..end_time], deed_type: DeedType::PAGE_TRANSCRIPTION).order(:created_at)
      # bail out if there is only one deed
      if deeds.length < 2
        next
      end
      time_between_deeds = []
      deeds.each_with_index do |deed, index|
        if index != deeds.length - 1
          time_between_deeds << deeds[index + 1].created_at - deed.created_at
        end
      end
      # choose a threshold for the time between deeds
      threshold = 90.seconds
      # how many times was the threshold exceeded?
      threshold_exceeded = time_between_deeds.select { |time| time < threshold }.length
      # if the threshold was exceeded more than 3 times, print out the user's name
      if threshold_exceeded > 3
        puts user.display_name
      end
    end;0



  end
  desc "create a CSV file listing all pages in a collection and their contributors and status"
  task create_page_export_csv: :environment do
    collection = Collection.find(ARGV[1])
    CSV.open("pages.csv", "wb") do |csv|
      headers = %w[Work_Title Identifier Work_URL Page_Title Page_Position Page_URL Transcribe_URL Page_Status Contributors]
      csv << headers
      collection.pages.each do |page|
        row = [
          page.work.title,
          page.work.identifier,
          Rails.application.routes.url_helpers.collection_read_work_url(collection.owner, collection, page.work),
          page.title,
          page.position,
          Rails.application.routes.url_helpers.collection_display_page_url(collection.owner, collection, page.work, page),
          Rails.application.routes.url_helpers.collection_transcribe_page_url(collection.owner, collection, page.work, page),
          page.status,
          page.contributors.map { |hash| hash[:name] }.join(", ")
        ]
        csv << row
      end
    end
  end


end
