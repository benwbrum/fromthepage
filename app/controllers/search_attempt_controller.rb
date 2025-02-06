class SearchAttemptController < ApplicationController
  def create
    @result = SearchAttempt::Create.new(search_attempt_params: search_attempt_params, user: current_user).call
    @search_attempt = @result.search_attempt

    if @result.success?
      session[:search_attempt_id] = @search_attempt.id if @result.success?
      redirect_to @result.link

    # :nocov:
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append(
              'flash_wrapper',
              partial: '/shared/flash',
              locals: { type: :error, message: t('errors.error') }
            )
          ]
        end
      end
    end
    # :nocov:
  end

  def show
    @search_attempt = SearchAttempt.find_by(slug: params[:id])

    if @search_attempt.nil?
      flash[:error] = 'Search attempt not found'
      redirect_to landing_page_path
    else
      session[:search_attempt_id] = @search_attempt.id if session[:search_attempt_id] != @search_attempt.id

      # Get matching Collections and Docsets
      @search_results = @search_attempt.query_results
      # Get user_ids from the resulting search
      search_user_ids = User.search(@search_attempt.query).pluck(:id) + @search_results.map(&:owner_user_id)
      # Get matching users and users from Collections and DocSets search
      @owners = User.where(id: search_user_ids).where.not(account_type: nil)
    end
  end

  # Called from any search result link by ajax
  def click
    if session[:search_attempt_id].present?
      search_attempt = SearchAttempt.find(session[:search_attempt_id])
      search_attempt.increment!(:clicks)
    end

    head :ok
  end

  private

  def search_attempt_params
    params.permit(:search, :work_id, :collection_id, :document_set_id, :search_by_title)
  end
end
