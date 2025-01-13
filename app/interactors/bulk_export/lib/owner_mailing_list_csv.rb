class BulkExport::Lib::OwnerMailingListCsv
  def self.export(output, owner)
    path = 'mailing_list.csv'
    output.put_next_entry(path)
    output.write(csv_string(owner))
  end

  def self.csv_string(owner)
    rows = []
    headers = ['User Login', 'User Name', 'Email', 'Opt-In']
    collection_ids = owner.collections.map(&:id).sort
    deed_map = Deed.where(collection_id: collection_ids).group(:user_id, :collection_id).count
    user_ids = deed_map.keys.map { |e| e[0] }.uniq
    Collection.where(id: collection_ids).order(:id).each { |c| headers << c.title }

    User.where(id: user_ids).each do |user|
      row = []
      row << user.login
      row << user.display_name
      row << user.email
      row << user.activity_email

      collection_ids.each do |collection_id|
        row << deed_map[[user.id, collection_id]] || 0
      end

      rows << row
    end

    CSV.generate(headers: true) do |csv|
      csv << headers

      rows.each do |row|
        csv << row
      end
    end
  end
end
