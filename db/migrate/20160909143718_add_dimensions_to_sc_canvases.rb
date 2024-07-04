class AddDimensionsToScCanvases < ActiveRecord::Migration[5.0]

  def change
    add_column :sc_canvases, :height, :integer
    add_column :sc_canvases, :width, :integer
  end

end
