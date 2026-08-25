class AddCachedAiStatusColumnToPages < ActiveRecord::Migration[7.2]
  def change
    add_column :pages, :cached_ai_status, :string, null: false, default: 'not_started' unless Page.column_names.include? 'cached_ai_status'
  end
end
