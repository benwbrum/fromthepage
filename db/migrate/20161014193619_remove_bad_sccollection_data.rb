class RemoveBadSccollectionData < ActiveRecord::Migration[5.2]
  def change
    ScCollection.where("at_id IS NULL").destroy_all
  end
end
