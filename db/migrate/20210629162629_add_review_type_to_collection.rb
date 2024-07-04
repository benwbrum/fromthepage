class AddReviewTypeToCollection < ActiveRecord::Migration[5.0]

  def change
    add_column :collections, :review_type, :string
    Collection.where(review_workflow: true).update_all(review_type: Collection::ReviewType::REQUIRED)
    Collection.where(review_workflow: false).update_all(review_type: Collection::ReviewType::OPTIONAL)
    remove_column :collections, :review_workflow
  end

end
