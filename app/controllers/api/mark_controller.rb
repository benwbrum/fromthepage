class Api::MarkController < Api::ApiController
  
  before_action :serialize_coordinates, only: [:create, :update]
  before_action :set_mark, only: [:update, :destroy, :show]

  def public_actions
    return [:index]
  end

  def index
    marks = Mark.all
    responseMarks=[]
    marks.map{|mark| responseMarks.push(mark.valueObject) }
    render_serialized ResponseWS.default_ok(responseMarks)
  end
  
  def list_by_page
    marks = Mark.where(page_id: params[:page_id], layer_id: nil).all
    responseMarks=[]
    marks.map{|mark| responseMarks.push(mark.valueObject) }
    render_serialized ResponseWS.default_ok(responseMarks)
  end

  def list_by_layer
    marks = Mark.where(layer_id: params[:layer_id]).all
    responseMarks=[]
    marks.map{|mark| responseMarks.push(mark.valueObject) }
    render_serialized ResponseWS.default_ok(responseMarks)
  end

  def create
    @mark = Mark.new(mark_params, current_user)
    if @page
      @mark.page=@page
    end
    if @layer
      @mark.layer=@layer
    end

    if @mark.save
      render_serialized ResponseWS.ok("api.mark.create.success", @mark.valueObject)
    else
      render_serialized ResponseWS.default_error
    end
  end
  
  def update
    @mark.update_attributes(mark_params)
    render_serialized ResponseWS.ok("api.mark.update.success", @mark.valueObject)
  end
  
  def destroy
    @mark.destroy
    render_serialized ResponseWS.ok("api.mark.destroy.success", @mark.valueObject)
  end
  
  def show
    response_serialized_object(@mark)
  end
  
  private
    
    def mark_params
      params.permit(:text, :coordinates, :text_type, :shape_type, :page_id, :layer_id, :transcription_text, :translation_text, :semantic_text, :schema_type)
    end
    
    def set_mark
      @mark = Mark.find(params[:id])
      raise ActiveRecord::RecordNotFound unless @mark
    end
    
    def set_page
      @page = Page.find(params[:page_id])
    end

    def set_layer
      @layer = Layer.find(params[:layer_id])
    end
    
    def serialize_coordinates
      params[:coordinates] = params[:coordinates].to_json
    end
  
end
