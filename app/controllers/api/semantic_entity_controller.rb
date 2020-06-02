class Api::SemanticEntityController < Api::ApiController

  before_action :set_search_filter, only: [:list]

  def public_actions
    return [:list, :show]
  end

  def list
    response_serialized_object SemanticHelper.listEntities(@filter)
  end

  def show
    params.permit(:entity_id, :use_default_schema)
    response_serialized_object SemanticHelper.describeEntity(params[:entity_id], params[:use_default_schema])
  end

  private
    def set_search_filter
      params.permit(:filter)
      @filter = params[:filter] || {}
    end

end