class ArticleArticleLink < ApplicationRecord
  belongs_to :source_article, :class_name => 'Article', :foreign_key => 'source_article_id', optional: true
  belongs_to :target_article, :class_name => 'Article', :foreign_key => 'target_article_id', optional: true
end
