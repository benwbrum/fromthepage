
Thredded::TopicsController.class_eval do
  def search
    @query = params[:q].to_s
    # add messageboard_group_id
    messageboard_ids = @collection.messageboard_group.messageboards.map { |mb| mb.id }

    page_scope = topics_scope
      .where(messageboard_id: messageboard_ids)
      .search_query(@query)
      .order_recently_posted_first
      .includes(:categories, :last_user, :user)
      .send(Kaminari.config.page_method_name, current_page)
    return redirect_to(last_page_params(page_scope)) if page_beyond_last?(page_scope)
    @topics = Thredded::TopicsPageView.new(thredded_current_user, page_scope)
  end
end
