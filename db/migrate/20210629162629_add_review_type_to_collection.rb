class AddReviewTypeToCollection < ActiveRecord::Migration[5.0]
  def change
    # Backsupport for CI
    unless column_exists?(:collections, :review_type)
      add_column :collections, :review_type, :string
    end

    Collection.where(review_workflow: true).update_all(review_type: :required)
    Collection.where(review_workflow: false).update_all(review_type: :optional)
    remove_column :collections, :review_workflow
  end
end
