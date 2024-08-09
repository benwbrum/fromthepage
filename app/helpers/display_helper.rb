module DisplayHelper
  include AbstractXmlHelper

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
    if @page.work.ocr_correction
      true
    end
  end

  def notes_for(commentable)
    render({ :partial => 'note/notes', :locals => { :commentable => commentable }})
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
      @wording = t('.transcribe')
    end
  end

end
