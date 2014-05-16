module DisplayHelper
  include AbstractXmlHelper


  def notes_for( commentable )
    render({:partial => 'note/notes',
            :locals =>
              { :commentable => commentable
              }
            })
  end

end
