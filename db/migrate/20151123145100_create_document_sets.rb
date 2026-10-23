class CreateDocumentSets < ActiveRecord::Migration[5.0]
  def change
    create_table :document_sets do |t|
      t.boolean :is_public
      t.references :owner_user, index: true
      t.references :collection, index: true
      t.string :title
      t.text :description
      t.string :picture

      # Backsupport for CI
      t.integer :visibility

      t.timestamps
    end
  end
end
