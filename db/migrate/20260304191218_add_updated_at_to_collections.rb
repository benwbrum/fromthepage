class AddUpdatedAtToCollections < ActiveRecord::Migration[7.2]
  def change
    change_table :collections, bulk: true do |t|
      t.timestamp :updated_at, null: false, default: -> { 'NOW()' }
    end
  end
end
