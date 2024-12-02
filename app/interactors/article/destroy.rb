class Article::Destroy < ApplicationInteractor

  attr_accessor :article

  def initialize(article:, user:, collection:)
    @article    = article
    @user       = user
    @collection = collection

    super
  end

  def perform
    context.fail!(message: I18n.t('article.delete.must_remove_referring_links')) if article_has_referring_links
    context.fail!(message: I18n.t('article.delete.only_subject_owner_can_delete')) unless user_can_delete_article

    @article.destroy
  end

  private

  def article_has_referring_links
    !(@article.link_list.empty? && @article.target_article_links.empty?)
  end

  def user_can_delete_article
    @article.created_by_id == @user.id || @user.like_owner?(@collection)
  end

end
