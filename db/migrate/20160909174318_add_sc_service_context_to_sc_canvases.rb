class AddScServiceContextToScCanvases < ActiveRecord::Migration[5.0]
  def change
    add_column :sc_canvases, :sc_service_context, :string
  end
end
