Thredded::MessageboardsController.class_eval do
  def create
    @new_messageboard = Thredded::Messageboard.new(messageboard_params)
    authorize_creating @new_messageboard
    if Thredded::CreateMessageboard.new(@new_messageboard, thredded_current_user).run
      redirect_to Thredded::UrlsHelper.show_messageboard_group_path(@collection.messageboard_group)
    else
      render :new
    end
  end
end
