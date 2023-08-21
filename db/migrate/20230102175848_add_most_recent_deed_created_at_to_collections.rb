class AddMostRecentDeedCreatedAtToCollections < ActiveRecord::Migration[6.0]
  def change
    add_column :collections, :most_recent_deed_created_at, :datetime

    Collection.includes(:deeds).each do |collection|
      unless collection.deeds.empty?
        collection.update_column(:most_recent_deed_created_at, collection.deeds.first.created_at)
      else
        collection.update_column(:most_recent_deed_created_at, collection.created_on)
      end
    end
  end
end
