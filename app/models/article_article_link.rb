# == Schema Information
#
# Table name: article_article_links
#
#  id                :integer          not null, primary key
#  created_on        :datetime
#  display_text      :string(255)
#  source_article_id :integer
#  target_article_id :integer
#
# Indexes
#
#  index_article_article_links_on_source_article_id  (source_article_id)
#  index_article_article_links_on_target_article_id  (target_article_id)
#
class ArticleArticleLink < ApplicationRecord
  belongs_to :source_article, :class_name => 'Article', :foreign_key => 'source_article_id', optional: true
  belongs_to :target_article, :class_name => 'Article', :foreign_key => 'target_article_id', optional: true
end
