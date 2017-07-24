class AddReviewToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :review_workflow, :boolean, default: false
  end
end
