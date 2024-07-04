class AddLineCountToPages < ActiveRecord::Migration[5.0]

  def change
    add_column :pages, :line_count, :integer unless column_exists?(:pages, :line_count)
    add_column :work_statistics, :line_count, :integer unless column_exists?(:work_statistics, :line_count)
  end

end
