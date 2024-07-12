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
      .where(status: :needs_review).count
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

  def reviewers_with_count
    contributor_deeds_by_type(DeedType::PAGE_REVIEWED, self.all_collaborators, self.collection_ids)
  end

  #this is to prevent an error in the statistics view
  def subjects_disabled
    false
  end

  private
  def contributor_deeds_by_type(deed_type, contributors, collections)
    user_array = []
    deeds_by_user = Deed.group('user_id').where(collection_id: collections).where(deed_type: deed_type).order('count_id desc').count('id')
    deeds_by_user.each { |user_id, count| user_array << [ contributors.find { |u| u.id == user_id }, count ] }

    return user_array
  end
end
