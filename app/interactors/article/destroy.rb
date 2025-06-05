class Article::Destroy < ApplicationInteractor
  attr_accessor :article

  def initialize(article:, user:, collection:)
    @article    = article
    @user       = user
    @collection = collection

    super
  end

  def perform
    context.fail!(message: I18n.t('article.delete.only_subject_owner_can_delete')) unless user_can_delete_article

    @article.destroy!

    Article::RenameJob.perform_later(
      article_id: @article.id,
      old_name: @article.title,
      new_name: ''
    )
  end

  private

  def user_can_delete_article
    @article.created_by_id == @user.id || @user.like_owner?(@collection)
  end
end
