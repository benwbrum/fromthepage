class CreateAiJobs < ActiveRecord::Migration[5.0]
  def change
    create_table :ai_jobs do |t|
      t.string :job_type
      t.string :engine
      t.text :parameters
      t.string :status
      t.references :page, null: true, foreign_key: true
      t.references :work, null: true, foreign_key: true
      t.references :collection, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_reference :external_api_requests, :ai_job, null: true, foreign_key: true
  end
end
