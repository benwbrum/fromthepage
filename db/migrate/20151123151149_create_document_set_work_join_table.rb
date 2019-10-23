class CreateDocumentSetWorkJoinTable < ActiveRecord::Migration[5.2]
  def change
    create_join_table :document_sets, :works do |t|
      # t.index [:document_set_id, :work_id]
      t.index [:work_id, :document_set_id], unique: true
    end
  end
end
