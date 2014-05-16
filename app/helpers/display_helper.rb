module DisplayHelper
  include AbstractXmlHelper

  def notes_for( commentable )
    render 'note/notes', :commentable => commentable
  end
end
