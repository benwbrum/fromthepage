class AddAiJobToExternalApiRequest < ActiveRecord::Migration[5.0]
  def change
    add_reference :external_api_requests, :ai_job, null: true, foreign_key: true
  end
end
