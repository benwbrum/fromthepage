module OwnerExporter
  def detailed_activity_csv(owner, start_date, end_date)
    owner_collections = owner.all_owner_collections.map(&:id)
    collaborator_activity_csv(owner_collections, start_date, end_date)
  end

  def collaborator_activity_csv(owner_collections, start_date, end_date)
    dates = (start_date..end_date)

    headers = [
      'Username',
      'Email'
    ]

    headers += dates.map { |d| d.strftime('%b %d, %Y') }

    # Get Row Data (Users)
    contributor_ids_for_dates = AhoyActivitySummary
      .where(collection_id: owner_collections)
      .where('date BETWEEN ? AND ?', start_date, end_date).distinct.pluck(:user_id)

    contributors = User.where(id: contributor_ids_for_dates).order(:display_name)
    activity_by_user_and_date = AhoyActivitySummary
      .where(user_id: contributor_ids_for_dates)
      .where(collection_id: owner_collections)
      .where('date BETWEEN ? AND ?', start_date, end_date)
      .group(:user_id, :date)
      .sum(:minutes)
      .transform_keys { |(user_id, date)| [user_id, date.to_date] }

    csv = CSV.generate(headers: true) do |records|
      records << headers
      contributors.each do |user|
        row = [user.display_name, user.email]

        user_activity = dates.map { |d| activity_by_user_and_date[[user.id, d.to_date]] || 0 }

        row += user_activity

        records << row
      end
    end

    csv
  end

  def get_data
    @collections = current_user.all_owner_collections
    @notes = current_user.notes
    @works = current_user.owner_works
    @ia_works = current_user.ia_works
    @document_sets = current_user.document_sets
  end


  def owner_mailing_list_csv(owner)
    rows = []
    header = ['User Login', 'User Name', 'Email', 'Opt-In']
    collection_ids = owner.collections.map { |c| c.id }.sort
    deed_map = Deed.where(collection_id: collection_ids).group(:user_id, :collection_id).count
    user_ids = deed_map.keys.map { |e| e[0] }.uniq
    Collection.where(id: collection_ids).order(:id).each { |c| header << c.title }

    User.find(user_ids).each do |user|
      row = []
      row << user.login
      row << user.display_name
      row << user.email
      row << user.activity_email

      collection_ids.each do |collection_id|
        row << (deed_map[[user.id, collection_id]] || 0)
      end

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
