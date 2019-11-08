#     # foreign keys
#      t.column :page_id, :integer
#      t.column :article_id, :integer
#      # text
#      t.column :display_text, :string
#      # automated stuff
#      t.column :created_on, :datetime
class PageArticleLink < ApplicationRecord
  belongs_to :page, optional: true
  belongs_to :article, optional: true

  # there were mass assignment errors in test
  attr_accessible :display_text, :page, :article
  attr_accessible :text_type

end
