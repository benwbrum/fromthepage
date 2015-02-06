module DisplayHelper
  include AbstractXmlHelper

  def has_translation?
    @work.supports_translation && !@page.source_translation.blank?
  end

  def translation_mode?
    # this expects a page to exist
    if @work.supports_translation
      if params[:translation].blank?
        true
      else
        params[:translation] != 'false'
      end 
    else
      false
    end
  end


  def notes_for( commentable )
    render({:partial => 'note/notes',
            :locals =>
              { :commentable => commentable
              }
            })
  end

end
