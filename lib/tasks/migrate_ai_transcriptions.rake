namespace :fromthepage do
  desc 'Migrate AI transcription for pages'
  task migrate_ai_transcription: :environment do
    root_path = Rails.root.join('public', 'text')

    Dir.each_child(root_path) do |folder|
      next if folder.end_with?('_processed')
      next unless folder =~ /^\d+$/

      folder_path = root_path.join(folder)

      next unless File.directory?(folder_path)

      processed_path = root_path.join("#{folder}_processed")

      puts "Processing folder #{folder}..."

      Dir.each_child(folder_path) do |filename|
        next unless filename.end_with?('_alto.xml', '_ai_plaintext.txt')

        page_id = filename.split('_').first.to_i
        if filename.include?('alto.xml')
          type = 'alto'
          model = AiTranscription::ALTO_MODEL
        else
          type = 'ai_plaintext'
          model = 'gemini-2.5-pro'
        end
        file_path = folder_path.join(filename)

        source_text = File.read(file_path)

        page = Page.find_by(id: page_id)

        next unless page.present?

        AiTranscription.create!(
          page_id: page.id,
          source_text: source_text,
          model: model
        )
      end

      File.rename(folder_path, processed_path)

      puts "Finished #{folder}, renamed to #{folder}_processed"
    end

    puts 'Process completed'
  end

  desc 'Delete old ai_transcription files'
  task delete_ai_transcription_files: :environment do
    root_path = Rails.root.join('public', 'text')

    Dir.each_child(root_path) do |folder|
      next unless folder.end_with?('_processed')

      folder_path = root_path.join(folder)

      puts "Deleting #{folder_path}..."
      FileUtils.rm_rf(folder_path)
    end

    puts 'All processed folders deleted.'
  end
end
