class AddTimestampsToDocumentSetsWorks < ActiveRecord::Migration[5.0]
  def change
    add_timestamps :document_sets_works, null: true
  end
end
