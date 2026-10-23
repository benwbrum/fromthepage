class UpdateExistingAiTranscriptionStatus < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    AiTranscription.update_all("status = 'finished'")
  end
end
