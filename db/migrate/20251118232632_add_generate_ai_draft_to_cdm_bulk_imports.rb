class AddGenerateAiDraftToCdmBulkImports < ActiveRecord::Migration[7.1]
  def change
    add_column :cdm_bulk_imports, :generate_ai_draft, :boolean, default: false
  end
end
