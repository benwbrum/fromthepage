class AddUseOcrToIaWork < ActiveRecord::Migration[5.2]
  def change
    add_column :ia_works, :use_ocr, :boolean, :default => false
  end
end
