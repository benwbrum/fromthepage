class Api::PublicationController < Api::ApiController
  
   before_action :set_publication, only: [:show, :update, :destroy]


 def create
    @foro = Foro.find(params[:foro][:id])
    @publicacion = Publication.new
    @parent = nil
    if !params[:parent].nil?
      @parent = Publication.find(params[:parent][:id])
    end
    

    if !@parent.nil?
      @publicacion = @parent.children.create()
  
    end

    @publicacion.foro=@foro
    @publicacion.user=current_user
    @publicacion.text=params[:text]
    if  @publicacion.save
      render_serialized ResponseWS.ok("api.mark.create.success", @publicacion)
    else
      render_serialized ResponseWS.default_error
    end
  end


  def update
    @publicacion.update_attributes(publication_params)
    render_serialized ResponseWS.ok("api.contribution.transcription.update.success", @publicacion)
  end
  
  def destroy
    @publicacion.destroy
    render_serialized ResponseWS.ok("api.contribution.transcription.destroy.success", @publicacion)
  end
  
  def show
     response_serialized_object @publicacion
  end
  

  def list
    @publications = Publication.where(foro_id: params[:id])
    response_serialized_object @publications
  end


    def publication_params
      params.permit(:foro,:text,:parent)
    end
  
    
    def set_publication
      @publicacion = Publication.find(params[:id])
      raise ActiveRecord::RecordNotFound unless @publicacion
    end



end
