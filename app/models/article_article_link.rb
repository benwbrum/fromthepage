class ArticleArticleLink < ActiveRecord::Base
  belongs_to :source_article, :class_name => 'Article', :foreign_key => 'source_article_id'
  belongs_to :target_article, :class_name => 'Article', :foreign_key => 'target_article_id'
end
