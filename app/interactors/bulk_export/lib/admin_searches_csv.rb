class BulkExport::Lib::AdminSearchesCsv
  def self.export(output, owner, report_arguments)
    path = 'admin_searches.csv'

    output.put_next_entry(path)
    output.write(csv_string(owner, report_arguments))
    output.write(
      csv_string(
        report_arguments['start_date'].to_datetime,
        report_arguments['end_date'].to_datetime
      )
    )
  end

  def self.csv_string(start_date, end_date)
    rows = []
    header = [
      'Query', 'Date', 'Search Type', 'Collection Title', 'Collection ID',
      'Work Title', 'Work ID', 'Hits', 'Clicks', 'Contributions', 'Visit ID',
      'User ID', 'Owner'
    ]

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

    CSV.generate(headers: true) do |csv|
      csv << header
      rows.each do |row|
        csv << row
      end
    end
  end
end
