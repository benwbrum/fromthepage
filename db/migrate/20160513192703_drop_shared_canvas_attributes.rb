class DropSharedCanvasAttributes < ActiveRecord::Migration[5.2]
  def self.up
	remove_column :sc_canvases, :sc_canvas_width
	remove_column :sc_canvases, :sc_canvas_height
	remove_column :sc_canvases, :sc_image_motivation
	remove_column :sc_canvases, :sc_image_on
	remove_column :sc_canvases, :sc_resource_id
	remove_column :sc_canvases, :sc_resource_format
	remove_column :sc_canvases, :sc_resource_type
	remove_column :sc_canvases, :sc_service_context
	remove_column :sc_canvases, :sc_service_profile	
  end

end
