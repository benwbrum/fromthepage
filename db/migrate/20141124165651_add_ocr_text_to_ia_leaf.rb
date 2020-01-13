class AddOcrTextToIaLeaf < ActiveRecord::Migration[5.2]
  def change
    add_column :ia_leaves, :ocr_text, :text
  end
end
