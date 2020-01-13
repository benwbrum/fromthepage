class CreateScCanvases < ActiveRecord::Migration[5.2]
  def change
    create_table :sc_canvases do |t|
      t.string :sc_id
      t.references :sc_manifest, index: true
      t.references :page, index: true
      t.string :sc_canvas_id
      t.string :sc_canvas_label
      t.integer :sc_canvas_width
      t.integer :sc_canvas_height
      t.string :sc_image_motivation
      t.string :sc_image_on
      t.string :sc_resource_id
      t.string :sc_resource_format
      t.string :sc_resource_type
      t.string :sc_service_context
      t.string :sc_service_id
      t.string :sc_service_profile

      t.timestamps
    end
  end
end
