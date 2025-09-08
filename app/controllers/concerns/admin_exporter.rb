module AdminExporter
  def admin_searches_csv(start_date, end_date)
    rows = []
    header = [ 'Query', 'Date', 'Search Type', 'Collection Title', 'Collection ID', 'Work Title', 'Work ID', 'Hits', 'Clicks', 'Contributions', 'Visit ID', 'User ID', 'Owner' ]

    start_date = start_date&.beginning_of_day || 1.week.ago.beginning_of_day
    end_date = end_date&.end_of_day || 1.day.ago.end_of_day
    searches = SearchAttempt.where('created_at BETWEEN ? AND ?', start_date, end_date).order(:created_at)
    searches.each do |search|
      row = []
      row << search.query
      row << search.created_at
      row << search.search_type
      row << search.collection&.title || ''
      row << search.collection_id || ''
      row << search.work&.title || ''
      row << search.work&.id || ''
      row << search.hits
      row << search.clicks
      row << search.contributions
      row << search.visit_id
      row << search.user_id
      row << search.owner
      rows << row
    end

    csv_string = CSV.generate(headers: true) do |csv|
      csv << header
      rows.each do |row|
        csv << row
      end
    end

    csv_string
  end
end
