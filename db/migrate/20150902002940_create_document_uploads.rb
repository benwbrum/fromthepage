class CreateDocumentUploads < ActiveRecord::Migration[5.0]
  def change
    create_table :document_uploads do |t|
      t.references :user, index: true
      t.references :collection, index: true
      t.string :file

      t.timestamps
    end
  end
end
