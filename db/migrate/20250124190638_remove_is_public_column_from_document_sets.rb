class RemoveIsPublicColumnFromDocumentSets < ActiveRecord::Migration[6.1]
  def up
    change_table :document_sets, bulk: true do |t|
      t.remove :is_public
    end
  end

  def down
    change_table :document_sets, bulk: true do |t|
      t.boolean :is_public
    end
  end
end
