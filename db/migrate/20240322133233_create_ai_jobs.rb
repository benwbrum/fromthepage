class CreateAiJobs < ActiveRecord::Migration[5.0]
  def change
    create_table :ai_jobs do |t|
      t.string :job_type
      t.string :engine
      t.string :parameters
      t.string :status
      t.references :work, null: true, foreign_key: true
      t.references :collection, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
