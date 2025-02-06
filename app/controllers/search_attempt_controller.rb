class SearchAttemptController < ApplicationController
  def create
    @result = SearchAttempt::Create.new(search_attempt_params: search_attempt_params, user: current_user).call
    @search_attempt = @result.search_attempt

    if @result.success?
      session[:search_attempt_id] = @search_attempt.id if @result.success?
      redirect_to @search_attempt.results_link
    end

    respond_to(&:turbo_stream)
  end

  def create_old
    owner = current_user.nil? ? false : current_user.owner
    query = params[:search]
    # Some of these objects may be nil, based on the search type
    work = Work.find(params[:work_id]) if params[:work_id].present?
    collection = Collection.find(params[:collection_id]) if params[:collection_id].present?
    document_set = DocumentSet.find(params[:document_set_id]) if params[:document_set_id].present?

    if params[:work_id].present?
      search_type = 'work'
    elsif (params[:collection_id].present? || params[:document_set_id].present?) && params[:search_by_title].present?
      search_type = 'collection-title'
      query = params[:search_by_title]
    elsif params[:collection_id].present? || params[:document_set_id].present?
      search_type = 'collection'
    else # Find a Project search
      search_type = 'findaproject'
    end

    query = query&.strip

    @search_attempt = SearchAttempt.new(
      query: query,
      search_type: search_type,
      work_id: work&.id,
      collection_id: collection&.id,
      document_set_id: document_set&.id,
      user_id: current_user&.id,
      owner: owner
    )
    @search_attempt.save
    session[:search_attempt_id] = @search_attempt.id
    ajax_redirect_to(@search_attempt.results_link)
  end

  def show
    @search_attempt = SearchAttempt.find_by(slug: params[:id])

    unless @search_attempt.nil?
      if session[:search_attempt_id] != @search_attempt.id
        session[:search_attempt_id] = @search_attempt.id
      end

      # Get matching Collections and Docsets
      @search_results = @search_attempt.results
      # Get user_ids from the resulting search
      search_user_ids = User.search(@search_attempt.query).pluck(:id) + @search_results.map(&:owner_user_id)
      # Get matching users and users from Collections and DocSets search
      @owners = User.where(id: search_user_ids).where.not(account_type: nil)
    else
      flash[:error] = "Search attempt not found"
      redirect_to landing_page_path
    end
  end

  # Called from any search result link by ajax
  def click
    if session[:search_attempt_id].present?
      search_attempt = SearchAttempt.find(session[:search_attempt_id])
      search_attempt.increment!(:clicks)
    end

    return head :ok
  end

  private

  def search_attempt_params
    params.permit(:search, :work_id, :collection_id, :document_set_id, :search_by_title)
  end
end
