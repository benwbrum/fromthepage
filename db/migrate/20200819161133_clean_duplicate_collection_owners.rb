class CleanDuplicateCollectionOwners < ActiveRecord::Migration[6.0]

  def change
    owner_map = CollectionOwner.select('DISTINCT user_id, collection_id').to_a
    return unless owner_map.size > 0

    CollectionOwner.delete_all
    CollectionOwner.insert_all!(owner_map.map(&:attributes))
  end

end
