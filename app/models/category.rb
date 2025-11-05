# == Schema Information
#
# Table name: categories
#
#  id                 :integer          not null, primary key
#  bio_fields_enabled :boolean          default(FALSE)
#  created_on         :datetime
#  gis_enabled        :boolean          default(FALSE), not null
#  org_fields_enabled :boolean
#  title              :string(255)
#  collection_id      :integer
#  parent_id          :integer
#
# Indexes
#
#  index_categories_on_collection_id  (collection_id)
#  index_categories_on_parent_id      (parent_id)
#
class Category < ApplicationRecord
  extend ActsAsTree::TreeView
  extend ActsAsTree::TreeWalker

  acts_as_tree order: 'title'
  belongs_to :collection, optional: true
  has_many :articles_categories
  has_many :articles, -> { distinct.order(:title) }, through: :articles_categories

  validates :title, presence: true, uniqueness: { scope: [:collection_id, :parent_id], case_sensitive: true }

  # def destroy_but_attach_children_to_parent
  #   self.children.each do |child|
  #     child.parent = self.parent
  #     child.save!
  #   end
  #   self.destroy
  # end

  def self.recursive_tree_for(collection_id)
    find_by_sql([<<~SQL, collection_id])
      WITH RECURSIVE tree AS (
        SELECT *
        FROM categories
        WHERE collection_id = ? AND parent_id IS NULL
        UNION ALL
        SELECT c.*
        FROM categories c
        JOIN tree t ON c.parent_id = t.id
      )
      SELECT *
      FROM tree
      ORDER BY title
    SQL
  end

  def self.ancestors_for(category_id)
    find_by_sql([<<~SQL, category_id])
      WITH RECURSIVE ancestors AS (
        SELECT id, parent_id, title, collection_id
        FROM categories
        WHERE id = ?

        UNION ALL

        SELECT c.id, c.parent_id, c.title, c.collection_id
        FROM categories c
        INNER JOIN ancestors a ON c.id = a.parent_id
      )
      SELECT *
      FROM ancestors;
    SQL
  end
end
