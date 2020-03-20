class Api::SemanticContributionController < Api::ApiController
  
  before_action :set_transcription, only: [:show, :update, :destroy]

  def public_actions
    return [:index]
  end

  def index
    transcriptions = Transcription.all
    render_serialized ResponseWS.default_ok(transcriptions)
  end
  
  def list_by_mark
    transcriptions = Transcription.where(mark_id: params[:mark_id]).order(cached_weighted_score: :desc).all
    render_serialized ResponseWS.default_ok(transcriptions)
  end

  def list_likes_by_user
    @list = Array.new()
    transcriptions = Transcription.where(mark_id: params[:mark_id]).all
    transcriptions.each do |transcription|
      element = Hash.new()
      element['id']=transcription.id
      #element['vote']= current_user.voted_for? transcription
      element['vote']= current_user.voted_as_when_voted_for(transcription)
      element['isVote']= current_user.voted_as_when_voted_for(transcription)
      
      @list.push(element)
      end
    render_serialized ResponseWS.default_ok(@list)
  end

  def transcription_like_by_user
    @list = Array.new()
    transcriptions = Transcription.where(id: params[:transcription_id]).all
    transcriptions.each do |transcription|
      element = Hash.new()
      element['id']=transcription.id
      element['vote']= current_user.voted_as_when_voted_for(transcription)
      element['isVote']= current_user.voted_as_when_voted_for(transcription)
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
    record_deed(@transcription)
    render_serialized ResponseWS.ok("api.contribution.transcription.like", @transcription)
  end


    def dislike
    @transcription = Transcription.find(params[:transcription_id])
    @transcription.downvote_from current_user
    @mark=@transcription.mark
    if(@transcription.better_than? @mark.transcription)
      @mark.transcription=@transcription
      @mark.save
     end
  
    render_serialized ResponseWS.ok("api.contribution.transcription.dislike", @transcription)
  end
  
  def show
    response_serialized_object @transcription
  end

  def record_deed(transcription)
    deed = stub_deed(transcription)
    deed.deed_type = Deed::TRASNCRIPTION_LIKE
    deed.save!
  end
  

def stub_deed(transcription)
    deed = Deed.new
    deed.page = @transcription.mark.page
    deed.work = @transcription.mark.page.work
    deed.collection = @transcription.mark.page.work.collection
    deed.user = current_user
    deed
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
