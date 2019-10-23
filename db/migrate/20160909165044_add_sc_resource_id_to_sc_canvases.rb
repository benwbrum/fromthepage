class AddScResourceIdToScCanvases < ActiveRecord::Migration[5.2]
  def change
    add_column :sc_canvases, :sc_resource_id, :string
  end
end
