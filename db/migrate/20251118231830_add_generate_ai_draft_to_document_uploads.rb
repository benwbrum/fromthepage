class AddGenerateAiDraftToDocumentUploads < ActiveRecord::Migration[7.1]
  def change
    add_column :document_uploads, :generate_ai_draft, :boolean, default: false
  end
end
