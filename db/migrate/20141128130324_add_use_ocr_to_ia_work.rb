class AddUseOcrToIaWork < ActiveRecord::Migration
  def change
    add_column :ia_works, :use_ocr, :boolean, :default => false
  end
end
