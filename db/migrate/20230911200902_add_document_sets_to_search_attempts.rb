class AddDocumentSetsToSearchAttempts < ActiveRecord::Migration[6.0]
  def change
    add_reference :search_attempts, :document_set, null: true
  end
end
