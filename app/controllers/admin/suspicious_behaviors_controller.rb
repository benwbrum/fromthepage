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

      if ELASTIC_ENABLED
        users_scope = filtered_es_users(search_user_term)
      else
        users_scope = filtered_users(search_user_term)
      end

      @filtered_scope = @filtered_scope.where(user_id: users_scope.select(:id))
    end

    if params[:search_collection].present?
      search_collection_term = params[:search_collection]

      if ELASTIC_ENABLED
        collection_ids = Collection.es_search(query: "~#{search_collection_term}~", user: current_user).pluck('_id')
        collections_scope = Collection.where(id: collection_ids)
      else
        collections_scope = Collection.where(id: search_collection_term)
          .or(Collection.where(slug: search_collection_term))
      end

      @filtered_scope = @filtered_scope.where(collection_id: collections_scope.select(:id))
    end

    if params[:search_owner].present?
      search_owner_term = params[:search_owner]

      if ELASTIC_ENABLED
        owners_scope = filtered_es_users(search_owner_term)
      else
        owners_scope = filtered_users(search_owner_term)
      end

      owner_filter = Collection.where(owner_user_id: owners_scope.select(:id))

      @filtered_scope = @filtered_scope.where(collection_id: owner_filter.select(:id))
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

  def filtered_es_users(query)
    user_ids = User.es_search(query: "~#{query}~", extra_fields: ['display_name', 'login']).pluck('_id')

    User.where(id: user_ids)
  end

  def filtered_users(query)
    User.where(id: query)
      .or(User.where(slug: query))
      .or(User.where('LOWER(email) LIKE LOWER(?)', "%#{query}%"))
      .or(User.where('LOWER(display_name) LIKE LOWER(?)', "%#{query}%"))
      .or(User.where('LOWER(real_name) LIKE LOWER(?)', "%#{query}%"))
  end
end
