module CollectionHelper
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

      if @progress_completed == 100
        @completed = "Completed"
      else
        @completed = "Not Completed"
      end

    elsif @progress_review == 0
      @wording = "#{@progress_annotated}% indexed, #{@progress_completed}% #{@type}"

    else
      @wording = "#{@progress_annotated}% indexed, #{@progress_completed}% #{@type}, #{@progress_review}% needs review"

      if @progress_annotated == 100
        @completed = "Completed"
      else
        @completed = "Not Completed"
      end

    end

  end

end