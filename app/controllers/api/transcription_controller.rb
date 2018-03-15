class Api::TranscriptionController < Api::ApiController
  
  before_action :set_transcription, only: [:show, :update, :destroy]

  def public_actions
    return [:index]
  end

  def index
    transcriptions = Transcription.all
    render_serialized ResponseWS.default_ok(transcriptions)
  end
  
  def list_by_mark
    transcriptions = Transcription.where(mark_id: params[:mark_id]).all
    transcriptions.each do |d|
      puts current_user.voted_for? d
      end
    render_serialized ResponseWS.default_ok(transcriptions)
  end


  def list_likes_by_user

    #transcriptions = Transcription.joins('votes on votes.votable_id = transcription.id and votes.voter_id = '+ current_user.id.to_s).where('transcription.mark.id = ' + params[:mark_id].to_s)
    @list = Array.new()
    transcriptions = Transcription.where(mark_id: params[:mark_id]).all
    transcriptions.each do |transcription|
      element = Hash.new()
      element['id']=transcription.id
      element['vote']= current_user.voted_for? transcription
      puts current_user.voted_for? transcription
      @list.push(element)
      end
    render_serialized ResponseWS.default_ok(@list)
  end



  def transcription_like_by_user

    #transcriptions = Transcription.joins('votes on votes.votable_id = transcription.id and votes.voter_id = '+ current_user.id.to_s).where('transcription.mark.id = ' + params[:mark_id].to_s)
    @list = Array.new()
    transcriptions = Transcription.where(id: params[:transcription_id]).all
    transcriptions.each do |transcription|
      element = Hash.new()
      element['id']=transcription.id
      element['vote']= current_user.voted_for? transcription
      puts current_user.voted_for? transcription
      @list.push(element)
      end
    render_serialized ResponseWS.default_ok(@list)
  end

  def create
    @transcription = Transcription.new(transcription_params)
    if @mark
      @transcription.mark = @mark
    end
    @transcription.user = current_user

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
    @transcription = Transcription.find(params[:transcription_id])
    @transcription.liked_by current_user
    @mark=@transcription.mark
    if(@transcription.better_than? @mark.transcription)
      @mark.transcription=@transcription
      @mark.save
    end
    render_serialized ResponseWS.ok("api.contribution.transcription.like", @transcription)
  end
  
  def show
    response_serialized_object @transcription
  end
  
  private
    
    def transcription_params
      params.permit(:text, :mark_id)
    end
    
    def set_transcription
      @transcription = Transcription.find(params[:id])
      raise ActiveRecord::RecordNotFound unless @transcription
    end
    
    def set_mark
      @mark = Mark.find(params[:mark_id])
    end
  
end
