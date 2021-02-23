class AddDocumentSetToDeeds < ActiveRecord::Migration[5.0]
  def change
    add_reference :deeds, :document_set, null: true, index: true
  end
end
