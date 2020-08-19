class CleanDuplicateCollectionOwners < ActiveRecord::Migration[6.0]
  def change
    owner_map = CollectionOwner.distinct.all.to_a
    CollectionOwner.delete_all
    CollectionOwner.insert_all!(owner_map.map{|obj| obj.attributes})
  end
end
