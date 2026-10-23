# == Schema Information
#
# Table name: articles_categories
#
#  article_id  :integer
#  category_id :integer
#
# Indexes
#
#  index_articles_categories_on_article_id_and_category_id  (article_id,category_id)
#
class ArticlesCategory < ApplicationRecord
  belongs_to :article
  belongs_to :category
end
