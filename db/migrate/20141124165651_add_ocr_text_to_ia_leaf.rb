class AddOcrTextToIaLeaf < ActiveRecord::Migration[5.0]

  def change
    add_column :ia_leaves, :ocr_text, :text
  end

end
