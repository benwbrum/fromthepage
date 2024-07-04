class RenameCollectionNotesToNotesCsv < ActiveRecord::Migration[6.0]

  def change
    rename_column :bulk_exports, :collection_notes, :notes_csv
  end

end
