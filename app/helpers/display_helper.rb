module DisplayHelper

  include AbstractXmlHelper

  def has_translation?
    @work.supports_translation && !@page.translation_status.nil?
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
    return false unless @page.work.ocr_correction

    true
  end

  def notes_for(commentable)
    render({ partial: 'note/notes', locals: { commentable: } })
  end

  def page_action(page)
    @path = collection_transcribe_page_path(params[:user_slug], params[:collection_id], params[:work_id], page)
    if page.status.nil?
      if page.work.ocr_correction
        @wording = t('.correct')
      else
        @wording = t('.transcribe')
      end
    elsif page.status == Page::STATUS_BLANK
      @wording = t('.blank_page')
      @path = collection_display_page_path(params[:user_slug], params[:collection_id], params[:work_id], page)
    elsif page.status == Page::STATUS_NEEDS_REVIEW
      @wording = t('.review')
    elsif page.work.supports_translation?
      @path = collection_translate_page_path(params[:user_slug], params[:collection_id], params[:work_id], page)
      if page.translation_status.nil?
        @wording = t('.translate')
      elsif page.translation_status == Page::STATUS_NEEDS_REVIEW
        @wording = t('.review')
      elsif page.translation_status == Page::STATUS_TRANSLATED
        if @collection.subjects_disabled
          @wording = t('.completed')
        else
          @wording = t('.index')
        end
      elsif page.translation_status == Page::STATUS_INDEXED
        @wording = t('.completed')
        @path = collection_display_page_path(params[:user_slug], params[:collection_id], params[:work_id], page)
      end
    elsif page.status == Page::STATUS_TRANSCRIBED
      if @collection.subjects_disabled
        @wording = t('.completed')
      else
        @wording = t('.index')
      end
    elsif page.status == Page::STATUS_INDEXED
      @wording = t('.completed')
      @path = collection_display_page_path(params[:user_slug], params[:collection_id], params[:work_id], page)
    else
      @wording = t('.transcribe')
    end
  end

end
