namespace :fromthepage do
  desc 'Migrate transcription JSON for pages'
  task :migrate_transcription_json, [:start_from_id] => :environment do |_t, args|
    start_from_id = args[:start_from_id].to_i
    start_from_id = 1 if start_from_id.zero?

    log_file = Rails.root.join('log', 'migrate_transcription_json.log')

    File.open(log_file, 'a') do |log|
      log.puts "Starting migration from Collection ID: #{start_from_id} at #{Time.current}"

      collections = Collection.where(id: start_from_id..Float::INFINITY)
                              .where(field_based: true)
                              .order(:id)

      collections.find_each do |collection|
        transcription_fields = collection.transcription_fields
                                         .order(:line_number, :position)

        spreadsheet_columns_map = SpreadsheetColumn.where(transcription_field_id: transcription_fields.select(:id))
                                                   .order(:position)
                                                   .group_by(&:transcription_field_id)

        grouped_transcription_fields = transcription_fields.group_by(&:line_number)

        pages_to_update = []

        collection.pages.where(transcription_json: nil).find_each do |page|
          field_cells = TranscriptionField::Lib::Utils.table_cells_to_field_cells(
            page: page,
            grouped_transcription_fields: grouped_transcription_fields,
            spreadsheet_columns_map: spreadsheet_columns_map
          )

          pages_to_update << TranscriptionField::Lib::Utils.parse_fields(page: page, field_cells: field_cells)

          log.puts "Processed Page ID: #{page.id} in Collection ID: #{collection.id} at #{Time.current}"
        end

        unless pages_to_update.empty?
          Page.import pages_to_update, on_duplicate_key_update: [:transcription_json, :source_text], batch_size: 1_000
          log.puts "Updated #{pages_to_update.size} pages in Collection ID: #{collection.id} at #{Time.current}"
        end
      end

      log.puts "Migration completed at #{Time.current}"
    end
  end
end
