class Api::ForoController < Api::ApiController
  
   before_action :set_foro, only: [:show, :update, :destroy]
   
  def create
    @foro = Foro.new
    @foro.user = current_user
    #ver como carajo obtener la trasncripcion de los parametros
    @clazzName=params[:element][:className]
    clazz = Object.const_get @clazzName
    @transcription=clazz.find(params[:element][:id])


    #@transcription=Transcription.find(params[:element][:transcription][:id])
    @foro.element=@transcription
    if  @foro.save

        render_serialized ResponseWS.ok("api.forum.create.success", @foro)
    else
      render_serialized ResponseWS.default_error
    end
  end

  def update
    @foro.update_attributes(foro_params)
    render_serialized ResponseWS.ok("api.forum.update.success", @foro)
  end
  
  def destroy
    @foro.destroy
    render_serialized ResponseWS.ok("api.forum.destroy.success", @foro)
  end

  def getByClass
      @foro = Foro.where("element_id = ? AND element_type = ?",params[:element_id],params[:className]).first
      response_serialized_object @foro
  end
  
  def show
     response_serialized_object @foro
  end

  

    def foro_params
      params.permit(:element)
    end
  
    
    def set_foro
      @foro = Foro.find(params[:id])
      raise ActiveRecord::RecordNotFound unless @foro
    end


end
