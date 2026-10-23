namespace :fromthepage do
  desc 'Generate a CSV of Claude vs Gemini AI transcription disagreement rates for pages in a work or collection'
  task :ai_disagreement_report, [:slug, :ignored_fields] => :environment do |_t, args|
    unless args.slug
      puts 'Usage: rake fromthepage:ai_disagreement_report[slug,ignored_field_labels_or_ids]'
      puts 'Example: rake fromthepage:ai_disagreement_report[my-work-slug]'
      puts 'Example: rake fromthepage:ai_disagreement_report[my-collection-slug]'
      exit 1
    end

    slug = args.slug

    work = Work.friendly.find(slug, allow_nil: true)
    collection = work.nil? ? Collection::Lib::SetFriendlyFind.perform(id: slug) : nil

    if work.nil? && collection.nil?
      puts "No work or collection found for slug: #{slug}"
      exit 1
    end

    report_collection = work ? work.collection : collection
    pages = work ? work.pages.includes(:work, :ai_transcriptions) : collection.pages.includes(:work, :ai_transcriptions)
    report_fields = report_collection.transcription_fields
                                     .includes(:spreadsheet_columns)
                                     .order(:line_number, :position)
                                     .reject { |field| %w[description instruction].include?(field.input_type) }
    ignored_field_identifiers = [args.ignored_fields, *args.extras]
      .compact
      .flat_map { |value| value.to_s.split(',') }
      .map(&:strip)
      .reject(&:blank?)
    ignored_fields = report_fields.select do |field|
      ignored_field_identifiers.include?(field.label) || ignored_field_identifiers.include?(field.id.to_s)
    end
    overall_fields = report_fields - ignored_fields

    field_value_for_comparison = lambda do |field, json|
      return '' if json.blank?

      value = json[field.id.to_s]
      return '' if value.blank?

      if field.input_type == 'spreadsheet' && value.is_a?(Array)
        cols = field.spreadsheet_columns
        value.filter_map do |row|
          row_text = cols.map { |column| row[column.id.to_s].to_s }.reject(&:blank?).join(' ')
          row_text.presence
        end.join(' ')
      else
        value.to_s
      end
    end

    normalize_text = lambda do |text|
      text.to_s.gsub(/[[:punct:]]/, '').downcase.gsub(/\s+/, ' ').strip
    end

    labeled_text_for_comparison = lambda do |fields, transcription|
      fields.map do |field|
        "#{field.label}: #{field_value_for_comparison.call(field, transcription.transcription_json)}"
      end.join("\n")
    end

    field_headers = report_fields.flat_map do |field|
      ["#{field.label} CDR", "#{field.label} Text-only CDR"]
    end

    filename = "ai_disagreement_#{slug}.csv"

    CSV.open(filename, 'wb') do |csv|
      csv << ['Work Title', 'Page Title', 'Page ID', 'Page Status', 'AI Tab URL', 'Transcribe Tab URL', 'Character Disagreement Rate', 'Misplaced FIelds', 'Case-insensitive CDR', 'Claude Text-only CER', 'Gemini Text-only CER', *field_headers, 'Missing Models']

      pages.each do |page|
        page_work = page.work
        page_collection = page_work.collection

        finished_transcriptions = page.ai_transcriptions.select { |t| t.status_finished? && t.model != AiTranscription::ALTO_MODEL }
        claude_transcription = finished_transcriptions.select { |t| t.engine == 'claude' }.max_by(&:created_at)
        gemini_transcription = finished_transcriptions.select { |t| t.engine == 'gemini' }.max_by(&:created_at)

        missing_models = []
        missing_models << 'Claude' if claude_transcription.nil?
        missing_models << 'Gemini' if gemini_transcription.nil?

        if missing_models.empty?
          claude_labeled_text = labeled_text_for_comparison.call(overall_fields, claude_transcription)
          gemini_labeled_text = labeled_text_for_comparison.call(overall_fields, gemini_transcription)
          disagreement_rate = page.send(:character_error_rate, claude_labeled_text, gemini_labeled_text)
          ci_disagreement_rate = page.send(:character_error_rate, claude_labeled_text.downcase, gemini_labeled_text.downcase)
        end

        field_disagreement_rates = report_fields.flat_map do |field|
          if missing_models.empty?
            claude_field_text = field_value_for_comparison.call(field, claude_transcription.transcription_json)
            gemini_field_text = field_value_for_comparison.call(field, gemini_transcription.transcription_json)
            [
              page.send(:character_error_rate, claude_field_text, gemini_field_text),
              page.send(:character_error_rate, normalize_text.call(claude_field_text), normalize_text.call(gemini_field_text))
            ]
          else
            [nil, nil]
          end
        end
        misplaced_fields = report_fields.zip(field_disagreement_rates.each_slice(2)).any? do |field, (_cdr, text_only_cdr)|
          !ignored_fields.include?(field) && text_only_cdr == 100.0
        end ? 'yes' : 'no'

        csv << [
          page_work.title,
          page.title,
          page.id,
          page.status,
          Rails.application.routes.url_helpers.collection_ai_text_page_url(page_collection.owner, page_collection, page_work, page),
          "#{Rails.application.routes.url_helpers.collection_transcribe_page_url(page_collection.owner, page_collection, page_work, page)}?ai_draft=1",
          disagreement_rate,
          misplaced_fields,
          ci_disagreement_rate,
          claude_transcription&.text_cer,
          gemini_transcription&.text_cer,
          *field_disagreement_rates,
          missing_models.join(' ')
        ]
      end
    end

    puts "Wrote #{filename}"
  end
end
