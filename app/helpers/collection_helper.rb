module CollectionHelper

  def link
    if params[:works] == 'show'
      @link_title = t('.incomplete_works')
      @link_type = "hide"
    elsif params[:works] == 'hide'
      @link_title = t('.show_all')
      @link_type = "show"
    else
      if @collection.hide_completed
        @link_title = t('.show_all')
        @link_type = "show"
      else
        @link_title = t('.incomplete_works')
        @link_type = "hide"
      end
    end
  end

  def all_complete
    #if the collection is completed transcribed/translated
    if @collection.pct_completed == 100
      #if it's set to hide completed and the show button hasn't been pressed, don't show
      if (@collection.hide_completed) && params[:works] != 'show'
        return true
      #if the hide button is pressed, don't show
      elsif params[:works] == 'hide'
        return true
      #otherwise do show
      else
        return false
      end
    end
  end

  def work_stats(work)
    @progress_blank = work.work_statistic.pct_blank.round
    unless work.supports_translation
      @progress_annotated = work.work_statistic.pct_annotated.round
      @progress_review = work.work_statistic.pct_needs_review.round
      @progress_completed = work.work_statistic.pct_completed.round
      if work.ocr_correction
        @type = t('collection.corrected')
      else
        @type = t('collection.transcribed')
      end
    else
      @progress_annotated = work.work_statistic.pct_translation_annotated.round
      @progress_review = work.work_statistic.pct_translation_needs_review.round
      @progress_completed = work.work_statistic.pct_translation_completed.round
      @type = t('collection.translated')
    end

    if @collection.subjects_disabled
      unless @progress_review == 0
        @wording = "#{@progress_completed+@progress_review}% #{@type}, #{@progress_review}% #{t('collection.needs_review')}"
      else
        @wording = "#{@progress_completed+@progress_review}% #{@type}"
      end
    elsif @progress_review == 0
      @wording = "#{@progress_annotated}% #{t('collection.indexed')}, #{@progress_completed}% #{@type}"
    else
      @wording = "#{@progress_annotated}% #{t('collection.indexed')}, #{@progress_completed+@progress_review}% #{@type}, #{@progress_review}% #{t('collection.needs_review')}"
    end
  end

  def find_transcribe_pages
   #find works with deeds in the last 48 hours (not including add the work)
   active_works = Deed.where.not(deed_type: DeedType::WORK_ADDED).where('created_at >= ?', 48.hours.ago).where(collection_id: @collection.id).distinct.pluck(:work_id)
    #get work ids for the rest of the works
    inactive_works = @collection.works.unrestricted.pluck(:id) - active_works
    #find pages in those works that aren't transcribed
    pages = Page.where(work_id: inactive_works).needs_transcription
    return pages
  end

  def find_untranscribed_page
    # Get first untranscribed work
    untranscribed_works = @collection.works.joins(:work_statistic).where(work_statistics: {complete: 0})
    
    if untranscribed_works.any?{|w| w.untranscribed?}
      work_ids = untranscribed_works.select{|w| w.untranscribed?}
    else
      work_ids = @collection.works.incomplete_transcription.order_by_recent_inactivity
    end
    Page.where({work_id: work_ids})
      .needs_transcription
      .reorder('position ASC')
      .first
  end

  def any_public_collections_with_document_sets?(collections_and_doc_sets)
    collections = collections_and_doc_sets.select { |c_or_ds| c_or_ds.class == Collection}
    collections.any? { |c| c.is_public && c.supports_document_sets }
  end

  def is_a_public_collection?(collection_or_document_set)
    collection_or_document_set.class == Collection && collection_or_document_set.is_public
  end

  def is_a_private_document_set?(collection_or_document_set)
    collection_or_document_set.class == DocumentSet && !collection_or_document_set.is_public
  end

end
