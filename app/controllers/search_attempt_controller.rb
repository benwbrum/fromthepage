class SearchAttemptController < ApplicationController
    def create
        user_id = current_user.nil? ? nil : current_user.id
        owner = current_user.nil? ? false : current_user.owner
        
        if params[:work_id].present?
            work =  Work.find(params[:work_id])
            @search_attempt = SearchAttempt.new(
                query: params[:search],
                search_type: "work",
                work_id: work.id,
                collection_id: work.collection_id,
                user_id: user_id,
                owner: owner
            )
            @search_attempt.save
            session[:search_attempt_id] = @search_attempt.id
            ajax_redirect_to(paged_search_path(@search_attempt))

        elsif params[:collection_id].present? && params[:search_by_title].present?
            collection = Collection.find(params[:collection_id])
            @search_attempt = SearchAttempt.new(
                query: params[:search_by_title],
                search_type: "collection-title",
                collection_id: collection.id,
                user_id: user_id,
                owner: owner
            )
            @search_attempt.save
            session[:search_attempt_id] = @search_attempt.id
            ajax_redirect_to(collection_path(collection.owner, collection.slug, search_attempt_id: @search_attempt.id))

        elsif params[:collection_id].present?
            collection_id = Collection.find(params[:collection_id]).id
            @search_attempt = SearchAttempt.new(
                query: params[:search],
                search_type: "collection",
                collection_id: collection_id,
                user_id: user_id,
                owner: owner
            )
            @search_attempt.save
            session[:search_attempt_id] = @search_attempt.id
            ajax_redirect_to(paged_search_path(@search_attempt))

        else # Find a Project search
            @search_attempt = SearchAttempt.new(
                query: params[:search], 
                search_type: "findaproject",
                user_id: user_id, 
                owner: owner
            )
            @search_attempt.save
            session[:search_attempt_id] = @search_attempt.id
            ajax_redirect_to(search_attempt_show_path(@search_attempt))
        end
    end

    def show
        @search_attempt = SearchAttempt.find_by(slug: params[:id])
        
        unless @search_attempt.nil?
            if session[:search_attempt_id] != @search_attempt.id
                session[:search_attempt_id] = @search_attempt.id
            end

            # Get matching Collections and Docsets
            @search_results = Collection.search(@search_attempt.query).unrestricted + DocumentSet.search(@search_attempt.query).unrestricted
            @search_attempt.update(hits: @search_results.count)

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
        # binding.pry
        puts "CLICK"
        # puts session.inspect
        if session[:search_attempt_id].present?
            search_attempt = SearchAttempt.find(session[:search_attempt_id])
            search_attempt.increment!(:clicks)
        end
        
        return head :ok
    end
end
