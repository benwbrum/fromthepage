class AddCompleteToCollection < ActiveRecord::Migration[5.2]
  #have to add to both collections and document sets
  def change
    add_column :collections, :pct_completed, :integer
    add_column :document_sets, :pct_completed, :integer
  end
end
