module OwnerStatistic

  def work_count
    self.owner_works.count
  end

  def page_count
    count = Page.where(work_id: self.owner_works.ids).count
  end

  def active_page_count
    inactive = Collection.where(is_active: false).pluck(:id)
    Page.joins(:work => :collection)
      .where(work_id: self.owner_works.ids)
      .where(:'collections.is_active' => true).count
  end
  
  def incomplete_page_count
    Page.where(work_id: self.owner_works.ids)
      .where(status: Page::NEEDS_WORK_STATUSES).count
  end
  
  def needs_review_count(days=nil)
    Page.where(work_id: self.owner_works.ids)
      .where(date_range_clause(days, "edit_started_at"))
      .where(status: Page::STATUS_NEEDS_REVIEW).count
  end
  
  def review_count(days=nil)
    Deed.where(work_id: self.owner_works.ids)
      .where(date_range_clause(days))
      .where(deed_type: DeedType::PAGE_REVIEWED).count
  end

  def owner_subjects
   Article.where(collection_id: self.all_owner_collections.ids)
  end

  def collection_ids
    [self.all_owner_collections.ids]
  end

  def subject_count(days=nil)
    owner_subjects.where(date_range_clause(days, 'created_on')).count
  end

  def mention_count(days=nil)
    PageArticleLink.where(article_id: owner_subjects.ids).where(date_range_clause(days, 'created_on')).count
  end

  def contributor_count(days=nil)
    User.joins(:deeds).where(deeds: {collection_id: collection_ids})
      .where.not(deeds: {deed_type: DeedType::COLLECTION_JOINED})
      .where(date_range_clause(days, 'deeds.created_at')).distinct.count
  end

  def comment_count(days=nil)
    Deed.where(collection_id: collection_ids).where(deed_type: DeedType::NOTE_ADDED).where(date_range_clause(days)).count

  end

  def transcription_count(days=nil)
    Deed.where(collection_id: collection_ids).where(deed_type: DeedType::PAGE_TRANSCRIPTION).where(date_range_clause(days)).count
  end

  def edit_count(days=nil)
    Deed.where(collection_id: collection_ids).where(deed_type: DeedType::PAGE_EDIT).where(date_range_clause(days)).count
  end

  def index_count(days=nil)
    Deed.where(collection_id: collection_ids).where(deed_type: DeedType::PAGE_INDEXED).where(date_range_clause(days)).count
  end

  def translation_count(days=nil)
    Deed.where(collection_id: collection_ids).where(deed_type: DeedType::PAGE_TRANSLATED).where(date_range_clause(days)).count
  end

  def ocr_count(days=nil)
    Deed.where(collection_id: collection_ids).where(deed_type: DeedType::OCR_CORRECTED).where(date_range_clause(days)).count
  end

  def date_range_clause(days, column = "created_at")
    if days.nil?
      return ""
    elsif days.is_a? Integer
      days = (days.days.ago)..(Time.now)
    end
    return {column.to_sym => days}
  end

  def all_collaborators
    User.joins(:deeds).where(deeds: {collection_id: collection_ids}).distinct
  end
  def all_owner_collections_updated_since(date_time_since)
    recently_changed = Collection.joins(:deeds)
      .includes(:deeds)
      .where("deeds.created_at > ?", date_time_since).distinct
    self.all_owner_collections & recently_changed
  end
  def new_collaborators_since(date_time_since)
    old_collaborators = User.joins(:deeds)
      .where(deeds: {collection_id: collection_ids})
      .where("deeds.created_at < ?", date_time_since).distinct
    self.all_collaborators - old_collaborators
  end

  ## Helper functions for Owner Stats partial. TODO: Order by number of Deeds, scoped to this owner
  def editors_with_count
    contributor_deeds_by_type(DeedType::PAGE_EDIT, self.all_collaborators, self.collection_ids)
  end

  def transcribers_with_count
    contributor_deeds_by_type(DeedType::PAGE_TRANSCRIPTION, self.all_collaborators, self.collection_ids)
  end

  def indexers_with_count
    contributor_deeds_by_type(DeedType::PAGE_INDEXED, self.all_collaborators, self.collection_ids)
  end

  #this is to prevent an error in the statistics view
  def subjects_disabled
    false
  end

  def contributors(start_date, end_date)
    User.where(id: contributor_ids_from_deeds(start_date, end_date)).order(:display_name)
  end

  # get each contributor's time on this owner's collections within the date range
  def contributor_time(start_date, end_date)
    contributor_ids = contributor_ids_from_deeds(start_date, end_date)

    # all distinct visits by users who logged deeds in date range affecting this owner's collections
    deed_visits = Visit.where("user_id in (?) and started_at between ? and ?", contributor_ids, start_date, end_date)

    # sum the time between the beginning of the visit and the last ahoy event for the session per user
    user_time = {} # user_time is each user's total time on FTP in the date range
    deed_visits.each do |visit|
      if visit.ahoy_events.last
        user_time[visit.user_id] = 0 unless user_time[visit.user_id]
        user_time[visit.user_id] += visit.ahoy_events.last.time - visit.started_at
      end
    end

    # minutes instead of seconds
    user_time.transform_values! do |time| (time/60 + 1).floor end
    
    # deed counts in the date range per user, for user_time_proportional
    # on any collections
    user_deeds_total       = Deed.where(user_id: contributor_ids) 
                                  .where("created_at >= ? AND created_at <= ?", start_date, end_date)
                                  .group('user_id').count
    # only on this owner's collections
    user_deeds_collections = Deed.where(user_id: contributor_ids)
                                  .where(collection_id: collection_ids)
                                  .where("created_at >= ? AND created_at <= ?", start_date, end_date)
                                  .group('user_id').count

    # get each user's approximate time on this owner's collections
    user_time_proportional = {}
    user_time.each do |user_id, total_time|
      if user_deeds_collections.has_key?(user_id) && user_deeds_total.has_key?(user_id)
        # the % of their deeds during this time period that were on this owner's collections
        weight = user_deeds_collections[user_id].to_f / user_deeds_total[user_id]
        user_time_proportional[user_id] = (user_time[user_id] * weight).round
      else
        user_time_proportional[user_id] = "No user #{user_id}"
      end
    end

    user_time_proportional
  end

  # get a specific user's time on this owner's collections per day, within the date range
  def contributor_time_for_user(user_id, start_date, end_date)
    # all distinct visits by the user within the date range
    deed_visits = Visit.where(user_id: user_id).where("started_at between ? and ?", start_date, end_date)

    # sum the time between the beginning of the visit and the last ahoy event for the session per day
    user_time = {} # user_time is this user's total time on FTP per day, within the date range
    deed_visits.each do |visit|
      if visit.ahoy_events.last
        user_time[visit.started_at.to_date] = 0 unless user_time[visit.started_at.to_date]
        user_time[visit.started_at.to_date] += visit.ahoy_events.last.time - visit.started_at
      end
    end

    # minutes instead of seconds
    user_time.transform_values! do |time| (time/60 + 1).floor end

    # deed counts in date range per day, for user_time_proportional
    # on any collections
    total_deeds =       Deed.where(user_id: user_id)
                            .where("created_at >= ? AND created_at <= ?", start_date, end_date)
                            .group_by{|deed| deed.created_at.to_date}.transform_values{|group| group.count} # better way to do this
    # only on this owner's collections
    collections_deeds = Deed.where(user_id: user_id)
                            .where(collection_id: collection_ids)
                            .where("created_at >= ? AND created_at <= ?", start_date, end_date)
                            .group_by{|deed| deed.created_at.to_date}.transform_values{|group| group.count} # better way to do this

    # get the user's approximate time on this owner's collections per day
    user_time_proportional = {}
    user_time.each do |date, total_time|
      if collections_deeds.has_key?(date) && total_deeds.has_key?(date)
        # the % of their deeds on this day that were on this owner's collections
        weight = collections_deeds[date].to_f / total_deeds[date]
        user_time_proportional[date] = (user_time[date] * weight).round
      else
        user_time_proportional[date] = user_time[date]
      end
    end

    user_time_proportional
  end

  private
  def contributor_deeds_by_type(deed_type, contributors, collections)
    user_array = []
    deeds_by_user = Deed.group('user_id').where(collection_id: collections).where(deed_type: deed_type).order('count_id desc').count('id')
    deeds_by_user.each { |user_id, count| user_array << [ contributors.find { |u| u.id == user_id }, count ] }

    return user_array
  end

  def contributor_ids_from_deeds(start_date, end_date)
    # get distinct user ids per deed to create list of user ids
    Deed.where(collection_id: collection_ids).where("created_at >= ? AND created_at <= ?", start_date, end_date).distinct.pluck(:user_id)
  end
end
