class AddCollectionsAndWorksToSearchAttempts < ActiveRecord::Migration[6.0]
  def change
    add_reference :search_attempts, :collection, null: true
    add_reference :search_attempts, :work, null: true
    add_column :search_attempts, :search_type, :string
  end
end
