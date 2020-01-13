class AddReviewToCollections < ActiveRecord::Migration[5.2]
  def change
    add_column :collections, :review_workflow, :boolean, default: false
  end
end
