class DropPercentageFromSpreadsheetColumns < ActiveRecord::Migration[5.0]

  def change
    remove_column :spreadsheet_columns, :percentage
  end

end
