class CreateEditorButtons < ActiveRecord::Migration[5.0]

  def change
    create_table :editor_buttons do |t|
      t.string :key
      t.references :collection, null: false, foreign_key: true
      t.boolean :prefer_html

      t.timestamps
    end
  end

end
