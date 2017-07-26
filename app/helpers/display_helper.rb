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
    if @page.work.ocr_correction
      true
    end
  end

  def notes_for(commentable)
    render({ :partial => 'note/notes', :locals => { :commentable => commentable }})
  end

  def page_action(page)
    @path = collection_transcribe_page_path(params[:user_slug], params[:collection_id], params[:work_id], page)
    if page.status.nil?
      if page.work.ocr_correction
        @wording = 'Correct'
      else
        @wording = 'Transcribe'
      end
    elsif page.status == 'blank'
      @wording = 'Blank page'
      @path = collection_display_page_path(params[:user_slug], params[:collection_id], params[:work_id], page)
    elsif page.status == 'review'
      @wording = 'Review'
    elsif page.work.supports_translation?
      @path = collection_translate_page_path(params[:user_slug], params[:collection_id], params[:work_id], page)
      if page.translation_status.nil?
        @wording = 'Translate'
      elsif page.translation_status == 'review'
        @wording = 'Review'
      elsif page.page_article_links.size == 0
        unless @collection.subjects_disabled
          @wording = 'Annotate'
        end
      end
    elsif page.page_article_links.size == 0
      unless @collection.subjects_disabled
        @wording = 'Annotate'
      end
    else
      @wording = 'Complete'
      @path = collection_display_page_path(params[:user_slug], params[:collection_id], params[:work_id], page)
    end
  end

end