class WidenOptionColumns < ActiveRecord::Migration[5.0]

  def change
    change_column :spreadsheet_columns, :options, :text
  end

end
