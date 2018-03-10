class Api::TranscriptionController < Api::ApiController
  
  before_action :set_transcription, only: [:update, :destroy, :like]

  def public_actions
    return [:index]
  end

  def index
    transcriptions = Transcription.all
    render_serialized ResponseWS.default_ok(transcriptions)
  end
  
  def list_by_mark
    transcriptions = Transcription.where(mark_id: params[:mark_id]).all
    render_serialized ResponseWS.default_ok(transcriptions)
  end

  def create
    @transcription = Transcription.new(transcription_params)
    if @mark
      @transcription.mark=@mark
    end

    if @transcription.save
      render_serialized ResponseWS.ok("api.contribution.transcription.create.success", @transcription)
    else
      render_serialized ResponseWS.default_error
    end
  end
  
  def update
    @transcription.update_attributes(transcription_params)
    render_serialized ResponseWS.ok("api.contribution.transcription.update.success", @transcription)
  end
  
  def destroy
    @transcription.destroy
    render_serialized ResponseWS.ok("api.contribution.transcription.destroy.success", @transcription)
  end
  
  def like
    @transcription.liked_by current_user
    @mark=@transcription.mark
    if(@transcription.better_than? @mark.transcription)
      @mark.transcription=@transcription
      @mark.save
    end
    render_serialized ResponseWS.ok("api.contribution.transcription.like", @transcription)
  end
  
  private
    
    def transcription_params
      params.permit(:text, :mark_id)
    end
    
    def set_transcription
      @transcription = Transcription.find(params[:transcription_id])
      raise ActiveRecord::RecordNotFound unless @transcription
    end
    
    def set_mark
      @mark = Mark.find(params[:mark_id])
    end
  
end
