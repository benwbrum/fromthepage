class AddLayerToMark < ActiveRecord::Migration
  def change
    add_reference :marks, :layer, index: true, foreign_key: true
  end
end
