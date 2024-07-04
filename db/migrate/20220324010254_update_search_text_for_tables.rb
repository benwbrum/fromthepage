class UpdateSearchTextForTables < ActiveRecord::Migration[5.0]

  def change
    table_page_ids = TranscriptionField.where(input_type: 'spreadsheet').to_a.map { |tf| tf.table_cells.pluck(:page_id) }.flatten.uniq
    print "updating search for #{table_page_ids.count} pages\n"
    Page.find(table_page_ids).each do |page|
      page.populate_search
      page.update_column(:search_text, page.search_text)
    end
  end

end
