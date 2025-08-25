class ChangeCollectionReviewType < ActiveRecord::Migration[5.0]
  def change
    change_column_default :collections, :review_type, 'optional'
  end
end
