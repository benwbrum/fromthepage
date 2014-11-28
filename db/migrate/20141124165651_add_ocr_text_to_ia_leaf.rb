class AddOcrTextToIaLeaf < ActiveRecord::Migration
  def change
    add_column :ia_leaves, :ocr_text, :text
  end
end
