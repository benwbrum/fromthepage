class CreatePageProcessingJobs < ActiveRecord::Migration[5.0]
  def change
    create_table :page_processing_jobs do |t|
      t.string :status
      t.references :ai_job, null: false, foreign_key: true
      t.references :page, null: false, foreign_key: true

      t.timestamps
    end
  end
end
