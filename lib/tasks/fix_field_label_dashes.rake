namespace :fromthepage do
  desc <<~DESC
    Regenerate xml_text for field-based pages affected by the field-label
    dash bug (TranscriptionField::Lib::Utils.parse_fields used the
    parameterized form-submission key instead of field.label, so e.g.
    "Drawing No." was rendered/exported as "drawing-no").

    Scoped to pages whose collection is field_based and whose updated_at is
    on/after the production deploy of the bug (PR #4578, deployed 2025-11-19
    13:06:59 CST) -- pages saved before that are unaffected and are skipped.

    transcription_json (the per-field value store) was never corrupted by
    the bug, so it's used as the source of truth to rebuild the label text
    correctly with the field's CURRENT label. Only xml_text is written, via
    update_column, so this does NOT create a page_version, does NOT touch
    source_text, and does NOT run any other save callbacks.

    Env vars:
      since    - ISO8601 timestamp; only pages updated at/after this are considered
                 (default: 2025-11-19T13:06:59-06:00, the production deploy time)
      dry_run  - 'true' (default) reports what would change without writing;
                 pass dry_run=false to actually update xml_text
      work_id  - restrict to a single work, for spot-checking before a full run
      page_id  - restrict to a single page, for spot-checking before a full run

    Examples:
      bundle exec rake fromthepage:fix_field_label_dashes
      bundle exec rake fromthepage:fix_field_label_dashes page_id=12345 dry_run=false
      bundle exec rake fromthepage:fix_field_label_dashes work_id=678 dry_run=false
  DESC
  task fix_field_label_dashes: :environment do
    since = ENV['since'].present? ? Time.zone.parse(ENV['since']) : Time.zone.parse('2025-11-19T13:06:59-06:00')
    dry_run = ENV['dry_run'] != 'false'

    puts "Scanning field-based pages updated at/after #{since} (dry_run=#{dry_run})"

    scope = Page.joins(work: :collection).where(collections: { field_based: true })
    scope = scope.where('pages.updated_at >= ?', since)
    scope = scope.where(work_id: ENV['work_id']) if ENV['work_id'].present?
    scope = scope.where(id: ENV['page_id']) if ENV['page_id'].present?

    scanned = 0
    changed = 0
    unchanged = 0
    skipped = 0
    errors = []

    scope.find_each do |page|
      scanned += 1

      begin
        next skipped += 1 if page.transcription_json.blank?

        collection = page.collection
        fields = collection.transcription_fields.includes(:spreadsheet_columns).order(:line_number, :position)

        field_cells = {}
        fields.each do |field|
          next if field.input_type == 'instruction'

          value = page.transcription_json[field.id.to_s]
          next if value.nil?

          field_value = if field.input_type == 'spreadsheet'
                          columns = field.spreadsheet_columns.order(:position)
                          value.map do |row|
                            columns.map { |column| row[column.id.to_s] }
                          end.to_json
          else
                          value.to_s
          end

          field_cells[field.id.to_s] = { 'value' => field_value }
        end

        if field_cells.empty?
          skipped += 1
          next
        end

        old_xml_text = page.xml_text

        # Mutates page.source_text / page.transcription_json in memory only --
        # this does not save the record.
        TranscriptionField::Lib::Utils.parse_fields(page: page, field_cells: field_cells)
        new_xml_text = page.wiki_to_xml(page, Page::TEXT_TYPE::TRANSCRIPTION, true)

        if new_xml_text == old_xml_text
          unchanged += 1
          next
        end

        changed += 1
        puts "Page #{page.id} (work #{page.work_id}): xml_text #{dry_run ? 'would change' : 'updated'}"

        page.update_column(:xml_text, new_xml_text) unless dry_run
      rescue StandardError => e
        errors << [page.id, e.message]
        puts "Page #{page.id}: ERROR #{e.message}"
      end
    end

    puts '---'
    puts "Scanned: #{scanned}, changed: #{changed}, unchanged: #{unchanged}, skipped (no field data): #{skipped}, errors: #{errors.size}"
    puts 'Re-run with dry_run=false to write these changes.' if dry_run && changed.positive?
  end
end
