Thredded::ModerationController.class_eval do
  private

  def preload_posts_for_moderation(posts)
    messageboard_ids = @collection.messageboard_group.messageboards.map{|mb| mb.id}
    posts.includes(:user, :messageboard, :postable).where(messageboard_id: messageboard_ids)
  end
end
