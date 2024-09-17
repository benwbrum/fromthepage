class AddDetailsToPageProcessingTask < ActiveRecord::Migration[6.1]
  def change
    add_column :page_processing_tasks, :details, :text
  end
end
