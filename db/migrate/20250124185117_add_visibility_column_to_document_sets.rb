class AddVisibilityColumnToDocumentSets < ActiveRecord::Migration[6.1]
  def up
    return if column_exists?(:document_sets, :visibility)

    change_table :document_sets, bulk: true do |t|
      t.integer :visibility, default: 0, null: false
    end
  end

  def down
    change_table :document_sets, bulk: true do |t|
      t.remove :visibility
    end
  end
end
