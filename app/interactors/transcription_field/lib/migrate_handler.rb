class TranscriptionField::Lib::MigrateHandler
  def initialize(collection:)
    @collection = collection
  end

  def perform
    log_file = Rails.root.join('log', 'migrate_transcription_json.log')

    File.open(log_file, 'a') do |log|
      log.puts "Migrating Collection ID: #{@collection.id} at #{Time.current}"

      transcription_fields = @collection.transcription_fields
                                        .order(:line_number, :position)

      spreadsheet_columns_map = SpreadsheetColumn.where(transcription_field_id: transcription_fields.select(:id))
                                                 .order(:position)
                                                 .group_by(&:transcription_field_id)

      grouped_transcription_fields = transcription_fields.group_by(&:line_number)

      pages_to_update = []

      @collection.pages.where(transcription_json: nil).find_each do |page|
        field_cells = TranscriptionField::Lib::Utils.table_cells_to_field_cells(
          page: page,
          grouped_transcription_fields: grouped_transcription_fields,
          spreadsheet_columns_map: spreadsheet_columns_map
        )

        pages_to_update << TranscriptionField::Lib::Utils.parse_fields(page: page, field_cells: field_cells)

        log.puts "Processed Page ID: #{page.id} in Collection ID: #{@collection.id} at #{Time.current}"
      end

      Page.import pages_to_update, on_duplicate_key_update: [:transcription_json, :source_text], batch_size: 1_000
      log.puts "Updated #{pages_to_update.size} pages in Collection ID: #{@collection.id} at #{Time.current}"
    end
  end
end
