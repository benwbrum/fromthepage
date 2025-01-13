class BulkExport::Lib::OwnerDetailedActivityCsv
  def self.export(output, owner, report_arguments)
    path = 'all_collaborator_time.csv'
    output.put_next_entry(path)
    output.write(csv_string(owner, report_arguments))
    output.write(
      csv_string(
        owner,
        report_arguments['start_date'].to_datetime,
        report_arguments['end_date'].to_datetime
      )
    )
  end

  def self.csv_string(owner, start_date, end_date)
    daterange = (start_date..end_date)
    headers = ['Username', 'Email']
    headers += daterange.map { |d| d.strftime('%b %d, %Y') }

    collections = owner.all_owner_collections

    activities = AhoyActivitySummary.where(collection_id: collections.select(:id))
                                    .where('date BETWEEN ? AND ?', start_date, end_date).distinct
    contributors = User.where(id: activities.select(:user_id)).order(:display_name)
    activities_hash_map = activities.group(:user_id, :date)
                                    .sum(:minutes)
                                    .transform_keys { |d| [d[0], d[1].to_date] }

    CSV.generate(headers: true) do |records|
      records << headers
      contributors.each do |user|
        row = [user.display_name, user.email]

        user_activity = daterange.map { |d| activities_hash_map[[user.id, d.to_date]] || 0 }

        row += user_activity

        records << row
      end
    end
  end
end
