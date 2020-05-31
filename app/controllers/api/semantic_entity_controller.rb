class Api::SemanticEntityController < Api::ApiController

  before_action :set_search_filter, only: [:list]

  def public_actions
    return [:list]
  end

  def list
    response_serialized_object SemanticHelper.listEntities(@filter)
  end

  private
    def set_search_filter
      params.permit(:filter)
      @filter = params[:filter] || {}
    end

end