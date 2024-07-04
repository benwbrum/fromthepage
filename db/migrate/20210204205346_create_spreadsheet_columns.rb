class CreateSpreadsheetColumns < ActiveRecord::Migration[5.0]

  def change
    create_table :spreadsheet_columns do |t|
      t.references :transcription_field, null: false, foreign_key: true
      t.integer :position
      t.string :label
      t.string :input_type
      t.string :options
      t.integer :percentage

      t.timestamps
    end
  end

end
