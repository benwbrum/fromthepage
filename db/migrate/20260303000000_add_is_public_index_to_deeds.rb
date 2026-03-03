class AddIsPublicIndexToDeeds < ActiveRecord::Migration[7.2]
  def change
    add_index :deeds, [:is_public, :created_at], name: 'index_deeds_on_is_public_and_created_at'
  end
end
