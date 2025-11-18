class AddAiDraftUsedToPageVersions < ActiveRecord::Migration[7.1]
  def change
    add_column :page_versions, :ai_draft_used, :boolean, default: false
  end
end
