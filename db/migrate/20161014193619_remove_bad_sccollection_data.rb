class RemoveBadSccollectionData < ActiveRecord::Migration[5.0]

  def change
    ScCollection.where(at_id: nil).destroy_all
  end

end
