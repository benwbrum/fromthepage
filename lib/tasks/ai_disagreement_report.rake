namespace :fromthepage do
  desc 'Generate a CSV of Claude vs Gemini AI transcription disagreement rates for pages in a work or collection'
  task :ai_disagreement_report, [:slug] => :environment do |_t, args|
    unless args.slug
      puts 'Usage: rake fromthepage:ai_disagreement_report[slug]'
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

    pages = work ? work.pages.includes(:work, :ai_transcriptions) : collection.pages.includes(:work, :ai_transcriptions)

    filename = "ai_disagreement_#{slug}.csv"

    CSV.open(filename, 'wb') do |csv|
      csv << ['Work Title', 'Page Title', 'Page ID', 'AI Tab URL', 'Transcribe Tab URL', 'Character Disagreement Rate', 'Missing Models']

      pages.each do |page|
        page_work = page.work
        page_collection = page_work.collection

        finished_transcriptions = page.ai_transcriptions.select { |t| t.status_finished? && t.model != AiTranscription::ALTO_MODEL }
        claude_transcription = finished_transcriptions.select { |t| t.engine == 'claude' }.max_by(&:created_at)
        gemini_transcription = finished_transcriptions.select { |t| t.engine == 'gemini' }.max_by(&:created_at)

        missing_models = []
        missing_models << 'Claude' if claude_transcription.nil?
        missing_models << 'Gemini' if gemini_transcription.nil?

        disagreement_rate = if missing_models.empty?
                              page.send(:character_error_rate, claude_transcription.text_for_comparison, gemini_transcription.text_for_comparison)
        end

        csv << [
          page_work.title,
          page.title,
          page.id,
          Rails.application.routes.url_helpers.collection_ai_text_page_url(page_collection.owner, page_collection, page_work, page),
          Rails.application.routes.url_helpers.collection_transcribe_page_url(page_collection.owner, page_collection, page_work, page),
          disagreement_rate,
          missing_models.join(', ')
        ]
      end
    end

    puts "Wrote #{filename}"
  end
end
