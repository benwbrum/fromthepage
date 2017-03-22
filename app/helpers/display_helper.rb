module DisplayHelper
  include AbstractXmlHelper

  def has_translation?
    @work.supports_translation && !@page.source_translation.blank?
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

end