class CreateCollectionReviewers < ActiveRecord::Migration[5.0]

  def change
    create_table :collection_reviewers do |t|
      t.references :user
      t.references :collection

      t.timestamps
    end
  end

end
