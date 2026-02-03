class Admin::SuspiciousBehaviorsController < AdminController
  DEFAULT_PER_PAGE = 200

  def index
    @suspicious_behaviors = filtered_scope

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    suspicious_behavior = SuspiciousBehavior.find(params[:id])

    render json: suspicious_behavior&.metadata || {}
  end

  private

  def filtered_scope
    @sorting = (params[:sort] || 'created_at').to_sym
    @ordering = (params[:order] || 'DESC').downcase.to_sym
    @ordering = [:asc, :desc].include?(@ordering) ? @ordering : :desc

    @filtered_scope = SuspiciousBehavior.includes(
      :user,
      { collection: :owner },
      :page,
      :resolved_by_user
    )

    status_filter = params[:status]&.downcase&.to_sym || :pending

    if (SuspiciousBehavior::STATUS_FILTERS - [:all]).include?(status_filter)
      @filtered_scope = @filtered_scope.where(status: status_filter)
    end

    type_filter = params[:behavior_type]&.downcase&.to_sym

    if (SuspiciousBehavior::BEHAVIOR_TYPE_FILTERS - [:all]).include?(type_filter)
      @filtered_scope = @filtered_scope.where(behavior_type: type_filter)
    end

    if params[:search_user].present?
      search_user_term = params[:search_user]
      user_filter = User.where(id: search_user_term)
        .or(User.where(slug: search_user_term))
        .or(User.where('LOWER(email) LIKE LOWER(?)', "%#{search_user_term}%"))
        .or(User.where('LOWER(display_name) LIKE LOWER(?)', "%#{search_user_term}%"))
        .or(User.where('LOWER(real_name) LIKE LOWER(?)', "%#{search_user_term}%"))
      if user_filter.any?
        @filtered_scope.where(user_id: user_filter.select(:id))
      else
        @filtered_scope = @filtered_scope.none
      end
    end

    if params[:search_collection].present?
      collection_filter = Collection.where(id: params[:search_collection]).or(Collection.where(slug: params[:search_collection]))
      if collection_filter.any?
        @filtered_scope.where(collection_id: collection_filter.select(:id))
      else
        @filtered_scope = @filtered_scope.none
      end
    end

    if params[:search_owner].present?
      search_owner_term = params[:search_owner]
      owner_filter = User.where(id: search_owner_term)
        .or(User.where(slug: search_owner_term))
        .or(User.where('LOWER(email) LIKE LOWER(?)', "%#{search_owner_term}%"))
        .or(User.where('LOWER(display_name) LIKE LOWER(?)', "%#{search_owner_term}%"))
        .or(User.where('LOWER(real_name) LIKE LOWER(?)', "%#{search_owner_term}%"))
      owner_filter = Collection.where(owner_user_id: owner_filter.select(:id))

      if owner_filter.any?
        @filtered_scope.where(collection_id: owner_filter.select(:id))
      else
        @filtered_scope = @filtered_scope.none
      end
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
end
