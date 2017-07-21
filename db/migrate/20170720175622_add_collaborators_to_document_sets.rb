class AddCollaboratorsToDocumentSets < ActiveRecord::Migration
  def self.up
    create_table :document_set_collaborators, :id => false do |t|
      t.integer :user_id
      t.integer :document_set_id
    end
  end

  def self.down
    drop_table :document_set_collaborators
  end
end
