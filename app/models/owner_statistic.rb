module OwnerStatistic
  def work_count
    self.statistics_works_scope.distinct.count
  end

  def page_count
    self.statistics_pages_scope.distinct.count
  end

  def active_page_count
    self.statistics_pages_scope.joins(work: :collection)
      .where('collections.is_active = TRUE')
      .distinct
      .count
  end

  def incomplete_page_count
    self.statistics_pages_scope.where(status: Page::NEEDS_WORK_STATUSES)
      .distinct
      .count
  end

  def needs_review_count(days = nil)
    self.statistics_pages_scope
      .where(date_range_clause(days, 'edit_started_at'))
      .where(status: :needs_review)
      .distinct
      .count
  end

  def review_count(days = nil)
    Deed.where(work_id: self.statistics_works_scope.select(:id))
      .where(date_range_clause(days))
      .where(deed_type: DeedType::PAGE_REVIEWED)
      .distinct
      .count(:work_id)
  end

  def subject_count(days = nil)
    self.statistics_subjects_scope.where(date_range_clause(days, 'created_on'))
      .distinct
      .count
  end

  def mention_count(days = nil)
    PageArticleLink.where(article_id: self.statistics_subjects_scope.select(:id))
      .where(date_range_clause(days, 'created_on'))
      .distinct
      .count
  end

  def contributor_count(days = nil)
    User.joins(:deeds).where(deeds: { collection_id: self.statistics_collections_scope.select(:id) })
      .where.not(deeds: { deed_type: DeedType::COLLECTION_JOINED })
      .where(date_range_clause(days, 'deeds.created_at'))
      .distinct
      .count
  end

  def comment_count(days = nil)
    if days.nil?
      Note.where(collection_id: self.statistics_collections_scope.select(:id)).distinct.count
    else
      Deed.where(collection_id: self.statistics_collections_scope.select(:id))
        .where(deed_type: DeedType::NOTE_ADDED)
        .where(date_range_clause(days)).distinct.count
    end
  end

  def transcription_count(days = nil)
    if days.nil?
      statistics_pages_scope.where(status: Page::COMPLETED_STATUSES).distinct.count
    else
      Deed.where(collection_id: self.statistics_collections_scope.select(:id))
        .where(deed_type: DeedType::PAGE_TRANSCRIPTION)
        .where(date_range_clause(days))
        .distinct
        .count
    end
  end

  def edit_count(days = nil)
    Deed.where(collection_id: self.statistics_collections_scope.select(:id))
      .where(deed_type: DeedType::PAGE_EDIT)
      .where(date_range_clause(days))
      .distinct
      .count
  end

  def index_count(days = nil)
    Deed.where(collection_id: self.statistics_collections_scope.select(:id))
      .where(deed_type: DeedType::PAGE_INDEXED)
      .where(date_range_clause(days))
      .distinct
      .count(:work_id)
  end

  def translation_count(days = nil)
    Deed.where(collection_id: self.statistics_collections_scope.select(:id))
      .where(deed_type: DeedType::PAGE_TRANSLATED)
      .where(date_range_clause(days))
      .distinct
      .count
  end

  def ocr_count(days = nil)
    Deed.where(collection_id: self.statistics_collections_scope.select(:id))
      .where(deed_type: DeedType::OCR_CORRECTED)
      .where(date_range_clause(days))
      .distinct
      .count
  end

  def date_range_clause(days, column = 'created_at')
    if days.nil?
      return ''
    elsif days.is_a? Integer
      days = (days.days.ago)..(Time.now)
    end

    { column.to_sym => days }
  end

  def all_collaborators
    self.statistics_collaborators_scope.distinct
  end

  def all_owner_collections_updated_since(date_time_since)
    recently_changed = Collection.joins(:deeds)
      .includes(:deeds)
      .where('deeds.created_at > ?', date_time_since).distinct

    self.statistics_collections_scope.where(id: recently_changed.select(:id)).distinct
  end

  def new_collaborators_since(date_time_since)
    self.statistics_collaborators_scope
      .group('users.id')
      .having('MIN(deeds.created_at) >= ?', date_time_since)
      .distinct
  end

  def contributor_deeds_by_type(deed_type, batch, batch_size)
    deeds_scope = Deed.joins(:user, :collection).where(collection_id: self.statistics_collections_scope.select(:id), deed_type: deed_type)
    entries_count = deeds_scope.distinct.count(:user_id)

    return {} if entries_count.zero?

    counts_map = deeds_scope.select('user_id, COUNT(deeds.id) AS count_id')
      .group(:user_id)
      .order(count_id: :desc)
      .limit(batch_size)
      .offset(batch)
      .count(:id)

    if entries_count > (batch + 1) * batch_size
      next_batch = batch + 1
    else
      next_batch = nil
    end

    {
      users_map: User.where(id: counts_map.keys).index_by(&:id),
      counts_map: counts_map,
      next_batch: next_batch
    }
  end

  def get_stats_hash(start_date = nil, end_date = nil)
    stats = {
      work_count: self.work_count,
      page_count: self.page_count,
      active_page_count: self.active_page_count,
      incomplete_page_count: self.incomplete_page_count
    }

    if start_date || end_date
      date_range = start_date..end_date

      stats = stats.merge({
        comment_count: self.comment_count(date_range),
        subject_count: self.subject_count(date_range),
        mention_count: self.mention_count(date_range),
        contributor_count: self.contributor_count(date_range),
        transcription_count: self.transcription_count(date_range),
        needs_review_count: self.needs_review_count(date_range),
        review_count: self.review_count(date_range),
        edit_count: self.edit_count(date_range),
        index_count: self.index_count(date_range),
        translation_count: self.translation_count(date_range),
        ocr_count: self.ocr_count(date_range)
      })
    else
      stats = stats.merge({
        comment_count: self.comment_count,
        subject_count: self.subject_count,
        mention_count: self.mention_count,
        contributor_count: self.contributor_count,
        transcription_count: self.transcription_count,
        needs_review_count: self.needs_review_count,
        review_count: self.review_count,
        edit_count: self.edit_count,
        index_count: self.index_count,
        translation_count: self.translation_count,
        ocr_count: self.ocr_count
      })
    end

    stats
  end

  # this is to prevent an error in the statistics view
  def subjects_disabled
    false
  end

  private

  # Note: There exist user specific functions like `owner_works`, `all_owner_collections`
  # But those include `distinct` and `order` SQL clauses, which slows down subqueries significantly
  # For optimization purposes, we will define those queries here without the unnecessary clauses
  def statistics_collections_scope
    Collection.where(owner_user_id: self.id)
      .or(Collection.where(id: self.owned_collections.select(:id)))
  end

  def statistics_works_scope
    Work.where(collection_id: self.statistics_collections_scope.select(:id))
  end

  def statistics_pages_scope
    Page.where(work_id: self.statistics_works_scope.select(:id))
  end

  def statistics_subjects_scope
    Article.where(collection_id: self.statistics_collections_scope.select(:id))
  end

  def statistics_collaborators_scope
    User.joins(:deeds).where(deeds: { collection_id: self.statistics_collections_scope.select(:id) })
  end
end
