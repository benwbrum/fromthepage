class AddScServiceContextToScCanvases < ActiveRecord::Migration
  def change
    add_column :sc_canvases, :sc_service_context, :string
  end
end
