class RemoveBadSccollectionData < ActiveRecord::Migration
  def change
    ScCollection.where("at_id IS NULL").destroy_all
  end
end
