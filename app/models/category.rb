class Category < ApplicationRecord
  extend ActsAsTree::TreeWalker

  acts_as_tree :order => 'title'
  belongs_to :collection, optional: true
  has_and_belongs_to_many :articles, -> { order('title').distinct }

  validates :title, presence: true, uniqueness: { scope: [:collection_id, :parent_id], case_sensitive: true }

  def articles_list(collection)
    if collection.is_a?(DocumentSet)
      Article.joins(:pages).where(pages: {work_id: collection.works.ids}).joins(:categories).where(categories: {id: self.id}).order(:title).distinct
    else
      self.articles
    end
  end

#  def destroy_but_attach_children_to_parent
#    self.children.each do |child|
#      child.parent = self.parent
#      child.save!
#    end
#    self.destroy
#  end
end
