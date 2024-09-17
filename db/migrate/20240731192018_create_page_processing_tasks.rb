class CreatePageProcessingTasks < ActiveRecord::Migration[5.0]
  def change
    create_table :page_processing_tasks do |t|
      t.string :type
      t.integer :position
      t.string :status
      t.references :page_processing_job, null: false, foreign_key: true

      t.timestamps
    end
  end
end
