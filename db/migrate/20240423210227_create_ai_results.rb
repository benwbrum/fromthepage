class CreateAiResults < ActiveRecord::Migration[5.0]
  def change
    create_table :ai_results do |t|
      t.string :task_type
      t.string :engine
      t.string :parameters
      t.string :result
      t.references :page, null: true, foreign_key: true
      t.references :work, null: true, foreign_key: true
      t.references :collection, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :ai_job, null: false, foreign_key: true
      t.references :external_api_request, null: false, foreign_key: true

      t.timestamps
    end
  end
end
