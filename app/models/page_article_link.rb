#     # foreign keys
#      t.column :page_id, :integer
#      t.column :article_id, :integer
#      # text
#      t.column :display_text, :string
#      # automated stuff
#      t.column :created_on, :datetime
# == Schema Information
#
# Table name: page_article_links
#
#  id           :integer          not null, primary key
#  created_on   :datetime
#  display_text :string(255)
#  text_type    :string(255)      default("transcription")
#  article_id   :integer
#  page_id      :integer
#
# Indexes
#
#  index_page_article_links_on_article_id  (article_id)
#  index_page_article_links_on_page_id     (page_id)
#
class PageArticleLink < ApplicationRecord

  belongs_to :page, optional: true
  belongs_to :article, optional: true

end
