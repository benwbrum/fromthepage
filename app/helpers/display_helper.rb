module DisplayHelper
  include AbstractXmlHelper

  def has_translation?
    @work.supports_translation && !@page.source_translation.blank?
  end

  def translation_mode?
    # this expects a page to exist
    @work.supports_translation && params[:translation] && params[:translation] != 'false'
  end


  def notes_for( commentable )
    render({:partial => 'note/notes',
            :locals =>
              { :commentable => commentable
              }
            })
  end

end
