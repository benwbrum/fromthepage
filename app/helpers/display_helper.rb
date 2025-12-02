module DisplayHelper
  include AbstractXmlHelper

  # Color coding for AI accuracy statistics based on Mark Humphries' definitions
  # CER thresholds: ≥3% red (untrustworthy), ≥1% yellow (needs review), ≤0.5% green (trustworthy)
  # WER thresholds: Double CER values - ≥6% red, ≥2% yellow, ≤1% green
  def accuracy_color_class(metric_type, value, text_only_wer = nil)
    case metric_type
    when :cer
      if value >= 3.0
        'stat-value-red'
      elsif value >= 1.0
        'stat-value-yellow'
      elsif value <= 0.5
        'stat-value-green'
      else
        'stat-value-yellow' # Between 0.5 and 1.0
      end
    when :wer
      if value >= 6.0
        'stat-value-red'
      elsif value >= 2.0
        'stat-value-yellow'
      elsif value <= 1.0
        'stat-value-green'
      else
        'stat-value-yellow' # Between 1.0 and 2.0
      end
    when :nsa
      # Compare with inverse of text-only WER
      return 'stat-value-yellow' if text_only_wer.nil?

      inverse_wer = 100.0 - text_only_wer
      # Allow for small floating point differences
      if (value - inverse_wer).abs < 0.01
        'stat-value-yellow'
      elsif value > inverse_wer
        'stat-value-green'
      else
        'stat-value-red'
      end
    else
      'stat-value-green'
    end
  end

  def has_translation?
    @work.supports_translation && !@page.translation_status_new?
  end

  def translation_mode?
    # this expects a page to exist
    if @work.supports_translation
      params[:translation] == 'true'
    else
      false
    end
  end

  def correction_mode?
    @page.work.ocr_correction
  end

  def notes_for(commentable)
    render({ partial: 'note/notes', locals: { commentable: commentable } })
  end

  def page_action(page)
    @path = collection_transcribe_page_path(params[:user_slug], params[:collection_id], params[:work_id], page)
    if page.status_new?
      if page.work.ocr_correction
        @wording = t('.correct')
      else
        @wording = t('.transcribe')
      end
    elsif page.status_blank?
      @wording = t('.blank_page')
      @path = collection_display_page_path(params[:user_slug], params[:collection_id], params[:work_id], page)
    elsif page.status_needs_review?
      @wording = t('.review')
    elsif page.work.supports_translation?
      @path = collection_translate_page_path(params[:user_slug], params[:collection_id], params[:work_id], page)
      if page.translation_status_new?
        @wording = t('.translate')
      elsif page.translation_status_needs_review?
        @wording = t('.review')
      elsif page.translation_status_translated?
        unless @collection.subjects_disabled
          @wording = t('.index')
        else
          @wording = t('.completed')
        end
      elsif page.translation_status_indexed?
        @wording = t('.completed')
        @path = collection_display_page_path(params[:user_slug], params[:collection_id], params[:work_id], page)
      end
    elsif page.status_transcribed?
      unless @collection.subjects_disabled
        @wording = t('.index')
      else
        @wording = t('.completed')
      end
    elsif page.status_indexed?
      @wording = t('.completed')
      @path = collection_display_page_path(params[:user_slug], params[:collection_id], params[:work_id], page)
    else
      @wording = t('.incomplete')
    end
  end
end
