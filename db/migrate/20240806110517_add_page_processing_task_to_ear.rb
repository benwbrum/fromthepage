class AddPageProcessingTaskToEar < ActiveRecord::Migration[5.0]
  def change
    add_reference :external_api_requests, :page_processing_task, null: true, foreign_key: true
  end
end
