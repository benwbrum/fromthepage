module CollectionHelper

  def link
    if params[:works] == 'show'
      @link_title = "Incomplete Works"
      @link_type = "hide"
    elsif params[:works] == 'hide'
      @link_title = "Show All"
      @link_type = "show"
    else
      if @collection.hide_completed
        @link_title = "Show All"
        @link_type = "show"
      else
        @link_title = "Incomplete Works"
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
    unless work.supports_translation
      @progress_annotated = work.work_statistic.pct_annotated.round
      @progress_review = work.work_statistic.pct_needs_review.round
      @progress_completed = work.work_statistic.pct_completed.round
      if work.ocr_correction
        @type = "corrected"
      else
        @type = "transcribed"
      end
    else
      @progress_annotated = work.work_statistic.pct_translation_annotated.round
      @progress_review = work.work_statistic.pct_translation_needs_review.round
      @progress_completed = work.work_statistic.pct_translation_completed.round
      @type = "translated"
    end

    if @collection.subjects_disabled
      unless @progress_review == 0
        @wording = "#{@progress_completed}% #{@type}, #{@progress_review}% needs review"
      else
        @wording = "#{@progress_completed}% #{@type}"
      end
    elsif @progress_review == 0
      @wording = "#{@progress_annotated}% indexed, #{@progress_completed}% #{@type}"
    else
      @wording = "#{@progress_annotated}% indexed, #{@progress_completed}% #{@type}, #{@progress_review}% needs review"
    end

  end

  def find_transcribe_pages
   #find works with deeds in the last 48 hours (not including add the work)
   active_works = Deed.where.not(deed_type: 'work_add').where('created_at >= ?', 48.hours.ago).where(collection_id: @collection.id).distinct.pluck(:work_id)
    #get work ids for the rest of the works
    inactive_works = @collection.works.unrestricted.pluck(:id) - active_works
    #find pages in those works that aren't transcribed
    pages = Page.where(work_id: inactive_works).needs_transcription
    return pages
  end

end