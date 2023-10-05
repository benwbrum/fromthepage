class AddAnnotationsToScCanvas < ActiveRecord::Migration[6.0]
  def change
    add_column :sc_canvases, :annotations, :text
  end
end
