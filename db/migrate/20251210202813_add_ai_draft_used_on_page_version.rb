class AddAiDraftUsedOnPageVersion < ActiveRecord::Migration[7.2]
  def change
    change_table :page_versions, bulk: true do |t|
      t.boolean :ai_draft_used, null: false, default: false
    end
  end
end
