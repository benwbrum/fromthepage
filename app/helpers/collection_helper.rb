module CollectionHelper

  def link
    if params[:works] == 'show'
      @link_title = t('.incomplete_works')
      @link_type = 'hide'
    elsif params[:works] == 'hide'
      @link_title = t('.show_all')
      @link_type = 'show'
    elsif @collection.hide_completed
      @link_title = t('.show_all')
      @link_type = 'show'
    else
      @link_title = t('.incomplete_works')
      @link_type = 'hide'
    end
  end

  def all_complete
    # if the collection is completed transcribed/translated
    return unless @collection.pct_completed == 100

    # if it's set to hide completed and the show button hasn't been pressed, don't show
    if @collection.hide_completed && params[:works] != 'show'
      true
    # if the hide button is pressed, don't show
    else
      params[:works] == 'hide'
    end
  end

  def collection_stats(collection)
    works = WorkStatistic.where(work_id: collection.works.pluck(:id))
    total_pages = works.sum(:total_pages)

    if total_pages == 0
      @progress_blank = 0
      @progress_annotated = 0
      @progress_review = 0
      @progress_completed = 0
    else
      total_blank_pages = works.sum(:blank_pages)
      total_annotated_pages = works.sum('annotated_pages + translated_annotated')
      total_review_pages = works.sum('needs_review + translated_review')
      total_completed_pages = works.sum('transcribed_pages + translated_pages')

      @progress_blank = (total_blank_pages.fdiv(total_pages) * 100).round
      @progress_annotated = (total_annotated_pages.fdiv(total_pages) * 100).round
      @progress_review = (total_review_pages.fdiv(total_pages) * 100).round
      @progress_completed = (total_completed_pages.fdiv(total_pages) * 100).round
    end

    if collection.subjects_disabled
      if @progress_review == 0
        @wording = "#{collection.pct_completed}% #{t('collection.complete')} " \
                   "(#{@progress_completed + @progress_review + @progress_blank}% #{t('collection.transcribed')})"
      else
        @wording = "#{collection.pct_completed}% #{t('collection.complete')} " \
                   "(#{@progress_completed + @progress_review + @progress_blank}% " \
                   "#{t('collection.transcribed')}, #{@progress_review}% #{t('collection.needs_review')})"
      end
    elsif @progress_review == 0
      @wording = "#{collection.pct_completed}% #{t('collection.complete')} " \
                 "(#{@progress_annotated}% #{t('collection.indexed')}, " \
                 "#{@progress_completed + @progress_blank}% #{t('collection.transcribed')})"
    else
      @wording = "#{collection.pct_completed}% #{t('collection.complete')} " \
                 "(#{@progress_annotated}% #{t('collection.indexed')}, " \
                 "#{@progress_completed + @progress_review + @progress_blank}% " \
                 "#{t('collection.transcribed')}, #{@progress_review}% #{t('collection.needs_review')})"
    end
  end

  def work_stats(work)
    @wording = ''
    @progress_blank = work.work_statistic.pct_blank.round
    if work.supports_translation
      @progress_annotated = work.work_statistic.pct_translation_annotated.round
      @progress_review = work.work_statistic.pct_translation_needs_review.round
      @progress_completed = work.work_statistic.pct_translation_completed.round
      @type = t('collection.translated')
      @transcribed_type = t('collection.transcribed')
    else
      @transcribed_type = nil if @transcribed_type.present?
      @progress_annotated = work.work_statistic.pct_annotated.round
      @progress_review = work.work_statistic.pct_needs_review.round
      @progress_completed = work.work_statistic.pct_completed.round
      if work.ocr_correction
        @type = t('collection.corrected')
      else
        @type = t('collection.transcribed')
      end
    end

    if @collection.subjects_disabled
      if @progress_review == 0
        @wording = "#{work.work_statistic.complete}% #{t('collection.complete')} (#{@progress_completed + @progress_review}% #{@type})"
      else
        @wording = "#{work.work_statistic.complete}% #{t('collection.complete')} (#{@progress_completed + @progress_review}% #{@type}, #{@progress_review}% #{t('collection.needs_review')})"
      end
    elsif @progress_review == 0
      if @transcribed_type.present?
        @wording = "#{work.work_statistic.complete}% #{t('collection.complete')} (#{@progress_annotated}% #{t('collection.indexed')}, #{@progress_completed}% #{@type}, #{work.work_statistic.pct_transcribed.round}% #{@transcribed_type})"
      else
        @wording = "#{work.work_statistic.complete}% #{t('collection.complete')} (#{@progress_annotated}% #{t('collection.indexed')}, #{@progress_completed}% #{@type})"
      end
    else
      @wording = "#{work.work_statistic.complete}% #{t('collection.complete')} (#{@progress_annotated}% #{t('collection.indexed')}, #{@progress_completed + @progress_review}% #{@type}, #{@progress_review}% #{t('collection.needs_review')})"
    end

    return unless @collection.metadata_entry?

    @wording += '. '
    @wording += t("work.#{work.description_status}")
  end

  def find_transcribe_pages
    # find works with deeds in the last 48 hours (not including add the work)
    active_works = Deed.where.not(deed_type: DeedType::WORK_ADDED).where(created_at: 48.hours.ago..).where(collection_id: @collection.id).distinct.pluck(:work_id)
    # get work ids for the rest of the works
    inactive_works = @collection.works.unrestricted.pluck(:id) - active_works
    # find pages in those works that aren't transcribed
    Page.where(work_id: inactive_works).needs_transcription
  end

  def find_untranscribed_page
    # Get first untranscribed work
    untranscribed_works = @collection.works.joins(:work_statistic).where(work_statistics: { complete: 0 })

    if untranscribed_works.any?(&:untranscribed?)
      work_ids = untranscribed_works.select(&:untranscribed?)
    else
      work_ids = @collection.works.incomplete_transcription.order_by_recent_inactivity
    end
    Page.where({ work_id: work_ids }).
      needs_transcription.
      reorder('position ASC').
      first
  end

  def any_public_collections_with_document_sets?(collections_and_doc_sets)
    collections = collections_and_doc_sets.select { |c_or_ds| c_or_ds.instance_of?(Collection) }
    collections.any? { |c| c.is_public && c.supports_document_sets }
  end

  def is_a_public_collection?(collection_or_document_set)
    collection_or_document_set.instance_of?(Collection) && collection_or_document_set.is_public
  end

  def is_a_private_document_set?(collection_or_document_set)
    collection_or_document_set.instance_of?(DocumentSet) && !collection_or_document_set.is_public
  end

end
