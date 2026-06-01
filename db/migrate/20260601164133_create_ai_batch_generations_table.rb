class CreateAiBatchGenerationsTable < ActiveRecord::Migration[7.2]
  def change
    create_table :ai_batch_generations, id: :integer do |t|
      t.references :collection
      t.references :work
      t.string :status, null: false, default: 'new'
      t.string :batch_key, index: true
    end
  end
end
