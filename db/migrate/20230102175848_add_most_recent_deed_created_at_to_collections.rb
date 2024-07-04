class AddMostRecentDeedCreatedAtToCollections < ActiveRecord::Migration[6.0]

  def change
    add_column :collections, :most_recent_deed_created_at, :datetime

    Collection.includes(:deeds).each do |collection|
      if collection.deeds.empty?
        collection.update_column(:most_recent_deed_created_at, collection.created_on)
      else
        collection.update_column(:most_recent_deed_created_at, collection.deeds.first.created_at)
      end
    end
  end

end
