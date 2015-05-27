class ArticleVersion < ActiveRecord::Base
  belongs_to :article
  belongs_to :user

  def prev
    article.article_versions.where("id < ?", id).first
  end

end