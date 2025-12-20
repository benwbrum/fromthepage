class SuspiciousBehaviorsController < ApplicationController
  DEFAULT_PER_PAGE = 200

  before_action :authorized?

  def index
    @suspicious_behaviors = filtered_scope

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    suspicious_behavior = @collection.suspicious_behaviors.find(params[:id])

    render json: suspicious_behavior&.metadata || {}
  end

  private

  def filtered_scope
    @sorting = (params[:sort] || 'created_at').to_sym
    @ordering = (params[:order] || 'DESC').downcase.to_sym
    @ordering = [:asc, :desc].include?(@ordering) ? @ordering : :desc

    @filtered_scope = @collection.suspicious_behaviors.includes(
      :user,
      :page,
      :resolved_by_user
    )

    status_filter = params[:status]&.downcase&.to_sym

    if (SuspiciousBehavior::STATUS_FILTERS - [:all]).include?(status_filter)
      @filtered_scope = @filtered_scope.where(status: status_filter)
    end

    type_filter = params[:behavior_type]&.downcase&.to_sym

    if (SuspiciousBehavior::BEHAVIOR_TYPE_FILTERS - [:all]).include?(type_filter)
      @filtered_scope = @filtered_scope.where(behavior_type: type_filter)
    end

    case @sorting
    when :resolved_at
      @filtered_scope = @filtered_scope.order(resolved_at: @ordering)
    else
      @filtered_scope = @filtered_scope.order(created_at: @ordering)
    end

    @filtered_scope = @filtered_scope.paginate(page: params[:page], per_page: DEFAULT_PER_PAGE)

    @filtered_scope
  end

  # TODO: Introduce permission concern
  def authorized?
    return if user_signed_in? && @collection.owner_user_id == current_user.id

    redirect_to dashboard_path
  end
end
