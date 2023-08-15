module OwnerExporter

  def detailed_activity_csv(owner, start_date, end_date)
    dates = (start_date..end_date)

    headers = [
      "Username",
      "Email"
    ]

    headers += dates.map{|d| d.strftime("%b %d, %Y")}

    # Get Row Data (Users)
    owner_collections = owner.all_owner_collections.map{ |c| c.id }


    contributor_ids_for_dates = AhoyActivitySummary
      .where(collection_id: owner_collections)
      .where('date BETWEEN ? AND ?', start_date, end_date).distinct.pluck(:user_id)

    contributors = User.where(id: contributor_ids_for_dates).order(:display_name)

    csv = CSV.generate(:headers => true) do |records|
      records << headers
      contributors.each do |user|
        row = [user.display_name, user.email]

        activity = AhoyActivitySummary
          .where(user_id: user.id)
          .where(collection_id: owner_collections)
          .where('date BETWEEN ? AND ?', start_date, end_date)
          .group(:date)
          .sum(:minutes)
          .transform_keys{ |k| k.to_date }

        user_activity = dates.map{ |d| activity[d.to_date] || 0 }

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
    deed_map = Deed.where(:collection_id => collection_ids).group(:user_id, :collection_id).count
    user_ids = deed_map.keys.map {|e| e[0]}.uniq
    Collection.where(:id => collection_ids).order(:id).each { |c| header << c.title }

    User.find(user_ids).each do |user|
      row = []
      row << user.login
      row << user.display_name
      row << user.email
      row << user.activity_email

      collection_ids.each do |collection_id|
        row << deed_map[[user.id,collection_id]] || 0
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

  def admin_searches_csv(start_date, end_date)
    rows = []
    header = ['Query', 'Date', 'Search Type', 'Collection Title', 'Collection ID', 'Work Title', 'Work ID', 'Hits', 'Clicks', 'Contributions', 'Visit ID', 'User ID', 'Owner']

    start_date = start_date&.beginning_of_day || 1.week.ago.beginning_of_day
    end_date = end_date&.end_of_day || 1.day.ago.end_of_day
    searches = SearchAttempt.where('created_at BETWEEN ? AND ?', start_date, end_date).order(:created_at)
    searches.each do |search|
      row = []
      row << search.query
      row << search.created_at
      row << search.search_type
      row << search.collection&.title || ""
      row << search.collection_id || ""
      row << search.work&.title || ""
      row << search.work&.id || ""
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