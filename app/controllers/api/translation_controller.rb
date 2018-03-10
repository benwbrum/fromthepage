class Api::TranslationController < Api::ApiController
  
  before_action :set_translation, only: [:update, :destroy]

  def public_actions
    return [:index]
  end

  def index
    translations = Translation.all
    render_serialized ResponseWS.default_ok(translations)
  end
  
  def list_by_mark
    translations = Translation.where(mark_id: params[:mark_id]).all
    render_serialized ResponseWS.default_ok(translations)
  end

  def create
    @translation = Translation.new(translation_params)
    if @mark
      @translation.mark=@mark
    end

    if @translation.save
      render_serialized ResponseWS.ok("api.translation.create.success", @translation)
    else
      render_serialized ResponseWS.default_error
    end
  end
  
  def update
    @translation.update_attributes(translation_params)
    render_serialized ResponseWS.ok("api.translation.update.success", @translation)
  end
  
  def destroy
    @translation.destroy
    render_serialized ResponseWS.ok("api.translation.destroy.success", @translation)
  end
  
  def like
    @translation.liked_by current_user
    @mark=@translation.mark
    if(@translation.better_than? @mark.translation)
      @mark.translation=@translation
      @mark.save
    end
    render_serialized ResponseWS.ok("api.contribution.translation.like", @translation)
  end
  
  private
    
    def translation_params
      params.permit(:text, :mark_id)
    end
    
    def set_translation
      @translation = Translation.find(params[:id])
      raise ActiveRecord::RecordNotFound unless @translation
    end
    
    def set_mark
      @mark = Mark.find(params[:mark_id])
    end
  
end
