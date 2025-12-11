namespace :fromthepage do
  desc 'Cleanup bad migration'
  task cleanup_ai_migration_folders: :environment do
    # first rename all of the folders in public/text that end with _processed back to original name
    root_path = Rails.root.join('public', 'text')
    Dir.each_child(root_path) do |folder|
      next unless folder.end_with?('_processed')
      original_folder = folder.sub('_processed', '')
      folder_path = root_path.join(folder)
      original_path = root_path.join(original_folder)
      puts "Renaming #{folder_path} back to #{original_path}..."
      File.rename(folder_path, original_path)
    end
    puts 'rename completed.'
  end

  desc 'Remove bad AI transcription records'
  task remove_bad_ai_transcriptions: :environment do
    AiTranscription.find_each do |transcription|
      page = transcription.page
      folder = Rails.root.join('public', 'text', page.work.id.to_s)
      ai_plaintext_path = folder.join("#{page.id}_ai_plaintext.txt")
      if File.exist?(ai_plaintext_path)
        puts "Deleting AiTranscription #{transcription.id} (#{transcription.model}) for page #{page.id}..."
        transcription.destroy!
      end
    end
    puts 'Bad AI transcriptions removed.'
  end


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

      Dir.children(folder_path).map { |filename| filename.split('_').first.to_i }.sort.uniq.each do |page_id|
        filename = "#{page_id}_ai_plaintext.txt"
        ai_plaintext_path = folder_path.join(filename)
        next unless File.exist?(ai_plaintext_path)
        alto_path = ai_plaintext_path.sub('ai_plaintext.txt', 'alto.xml')

        page = Page.find_by(id: page_id)
        next unless page.present?

        if alto_path && File.exist?(alto_path)
          type = 'alto'
          model = AiTranscription::ALTO_MODEL
          prompt = File.read(alto_path)
        else
          type = 'ai_plaintext'
          model = 'gemini-2.5-pro'
          prompt = nil
        end

        source_text = File.read(ai_plaintext_path)

        begin
          AiTranscription.create!(
            page_id: page.id,
            source_text: source_text.gsub('🤔', '?'),
            model: model,
            prompt: prompt
          )
        rescue => e
          puts "Error creating AiTranscription for page #{page.id}: #{e.message}"
        end
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
