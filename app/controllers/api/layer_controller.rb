class Api::LayerController < Api::ApiController
  
  before_action :set_layer, only: [:update, :destroy, :show]

  def public_actions
    return [:index]
  end

  def index
    layers = Layer.all
    responseLayers=[]
    layers.map{|layer| responseLayers.push(layer) }
    render_serialized ResponseWS.default_ok(responseLayers)
  end
  
  def list_by_page
    layers = Layer.where(page_id: params[:page_id]).all
    responseLayers=[]
    layers.map{|layer| responseLayers.push(layer) }
    render_serialized ResponseWS.default_ok(responseLayers)
  end

  def create
    @layer = Layer.new(layer_params, current_user)
    if @page
      @layer.page=@page
    end

    if @layer.save
      render_serialized ResponseWS.ok("api.layer.create.success", @layer)
    else
      render_serialized ResponseWS.default_error
    end
  end
  
  def update
    @layer.update_attributes(layer_params)
    render_serialized ResponseWS.ok("api.layer.update.success", @layer)
  end
  
  def destroy
    @layer.destroy
    render_serialized ResponseWS.ok("api.layer.destroy.success", @layer)
  end
  
  def show
    response_serialized_object(@layer)
  end
  
  private
    
    def layer_params
      params.permit(:name, :page_id)
    end
    
    def set_layer
      @layer = Layer.find(params[:id])
      raise ActiveRecord::RecordNotFound unless @layer
    end
    
    def set_page
      @page = Page.find(params[:page_id])
    end
  
end
