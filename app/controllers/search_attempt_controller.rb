class SearchAttemptController < ApplicationController
    def create
        @search_attempt = SearchAttempt.new(
            query: params[:search], 
            user_id: current_user.id, 
            owner: current_user.owner)
        @search_attempt.save
        
        ajax_redirect_to(search_attempt_show_path(@search_attempt.id))
    end

    def show
        @search_attempt = SearchAttempt.find(params[:id])
        session[:search_attempt_id] = @search_attempt.id

        # Get matching Collections and Docsets
        @search_results = Collection.search(@search_attempt.query).unrestricted + DocumentSet.search(@search_attempt.query).unrestricted
        @search_attempt.update(hits: @search_results.count)

        # Get user_ids from the resulting search
        search_user_ids = User.search(@search_attempt.query).pluck(:id) + @search_results.map(&:owner_user_id)
        # Get matching users and users from Collections and DocSets search
        @owners = User.where(id: search_user_ids).where.not(account_type: nil)
    end
end
