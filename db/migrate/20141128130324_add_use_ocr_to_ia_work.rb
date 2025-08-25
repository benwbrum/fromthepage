class AddUseOcrToIaWork < ActiveRecord::Migration[5.0]
  def change
    add_column :ia_works, :use_ocr, :boolean, default: false
  end
end
