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
        ai_plaintext_file = Dir.children(folder_path).find { |f| f.end_with?('_ai_plaintext.txt') }
        next unless ai_plaintext_file

        ai_plaintext_path = folder_path.join(ai_plaintext_file)

        alto_file = Dir.children(folder_path).find { |f| f.end_with?('_alto.xml') }
        alto_path = alto_file ? folder_path.join(alto_file) : nil

        page_id = filename.split('_').first.to_i
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

        AiTranscription.create!(
          page_id: page.id,
          source_text: source_text,
          model: model,
          prompt: prompt
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
