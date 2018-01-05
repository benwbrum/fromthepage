class AddTranscriptionFields < ActiveRecord::Migration
  def change
    add_column :collections, :field_based, :boolean, default: false

    create_table :transcription_fields do |t|
      t.column :label, :string
      t.column :collection_id, :integer
      t.column :input_type, :string
      t.column :options, :text
      t.column :line_number, :integer
      t.column :position, :integer
    end
  end
end
