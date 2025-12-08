namespace :fromthepage do
  namespace :gemini do
    desc 'Transcribe a single page using Gemini AI'
    task :transcribe_page, [:page_id, :model, :prompt_file] => :environment do |_t, args|
      require 'gemini/text_transcriber'
      unless args.page_id
        puts 'Usage: rake fromthepage:gemini:transcribe_page[page_id]'
        puts 'Example: rake fromthepage:gemini:transcribe_page[123]'
        puts 'Example: rake fromthepage:gemini:transcribe_page[123,gemini-2.5-pro,prompt.txt]'
        exit 1
      end
      model = args.model
      page = Page.find(args.page_id.to_i)
      if args.prompt_file.present?
        prompt = File.read(Rails.root.join(args.prompt_file))
      else
        prompt = nil
      end
      puts "Starting Gemini AI transcription for page ID: #{page.id} (#{page.title})"
      result = Page::FetchAiText.new(page: page, model: model, prompt: prompt).call
      if result.success?
        puts 'Transcription SUCCESS'
      else
        puts "Transcription ERROR - #{result.message}"
      end
    end

    desc 'Transcribe all pages in a work using Gemini AI (pass "retranscribe" to overwrite existing)'
    task :transcribe_work, [:work_slug, :retranscribe, :model, :prompt_file] => :environment do |_t, args|
      require 'gemini/text_transcriber'

      unless args.work_slug
        puts 'Usage: rake fromthepage:gemini:transcribe_work[work_slug,retranscribe]'
        puts 'Example: rake fromthepage:gemini:transcribe_work[my-work-slug]'
        puts 'Example: rake fromthepage:gemini:transcribe_work[my-work-slug,retranscribe]'
        exit 1
      end

      retranscribe = args.retranscribe == 'retranscribe'

      model = args.model

      # Find work by ID or slug
      work = if args.work_slug.match?(/^\d+$/)
               Work.find(args.work_slug.to_i)
      else
               Work.friendly.find(args.work_slug)
      end

      if args.prompt_file.present?
        prompt = File.read(Rails.root.join(args.prompt_file))
      else
        prompt = nil
      end

      puts "Starting Gemini AI transcription for work: #{work.title}"
      puts "Mode: #{retranscribe ? 'RETRANSCRIBE (will overwrite existing)' : 'NORMAL (skips existing)'}"
      puts "Total pages: #{work.pages.count}"
      puts '=' * 80

      success_count = 0
      skip_count = 0
      error_count = 0

      work.pages.each_with_index do |page, index|
        print "[#{index + 1}/#{work.pages.count}] Page #{page.id} (#{page.title}): "

        # Skip pages that already have ai_plaintext unless retranscribe mode
        if !retranscribe && page.ai_transcription.present?
          puts 'SKIPPED (already has AI plaintext)'
          skip_count += 1
          next
        end

        # Call the interactor
        result = Page::FetchAiText.new(page: page, model: model, prompt: prompt).call

        if result.success?
          puts 'SUCCESS'
          success_count += 1
        else
          puts "ERROR - #{result.message}"
          error_count += 1
        end

        # Small delay to avoid rate limiting
        sleep(0.5)
      end

      puts '=' * 80
      puts 'Transcription complete!'
      if retranscribe
        puts "Success: #{success_count}, Errors: #{error_count}"
      else
        puts "Success: #{success_count}, Skipped: #{skip_count}, Errors: #{error_count}"
      end
    end

    desc 'Transcribe all pages in all works in a collection using Gemini AI (pass "retranscribe" to overwrite existing)'
    task :transcribe_collection, [:collection_slug, :retranscribe, :model, :prompt_file] => :environment do |_t, args|
      require 'gemini/text_transcriber'

      unless args.collection_slug
        puts 'Usage: rake fromthepage:gemini:transcribe_collection[collection_slug,retranscribe]'
        puts 'Example: rake fromthepage:gemini:transcribe_collection[my-collection-slug]'
        puts 'Example: rake fromthepage:gemini:transcribe_collection[my-collection-slug,retranscribe]'
        exit 1
      end

      retranscribe = args.retranscribe == 'retranscribe'

      model = args.model

      # Find collection by ID or slug
      id = args.collection_slug
      if Collection.friendly.exists?(id)
        collection = Collection.friendly.find(id)
      elsif DocumentSet.friendly.exists?(id)
        collection = DocumentSet.friendly.find(id)
      elsif !DocumentSet.find_by(slug: id).nil?
        collection = DocumentSet.find_by(slug: id)
      elsif !Collection.find_by(slug: id).nil?
        collection = Collection.find_by(slug: id)
      end

      raise 'Collection does not exist' if collection.nil?

      if args.prompt_file.present?
        prompt = File.read(Rails.root.join(args.prompt_file))
      else
        prompt = nil
      end

      puts "Starting Gemini AI transcription for collection: #{collection.title}"
      puts "Mode: #{retranscribe ? 'RETRANSCRIBE (will overwrite existing)' : 'NORMAL (skips existing)'}"
      puts "Total works: #{collection.works.count}"

      total_pages = collection.works.sum { |w| w.pages.count }
      puts "Total pages: #{total_pages}"
      puts '=' * 80

      overall_success = 0
      overall_skip = 0
      overall_error = 0
      current_page = 0

      collection.works.each do |work|
        puts "\nProcessing work: #{work.title} (#{work.pages.count} pages)"
        puts '-' * 80

        work.pages.each do |page|
          current_page += 1
          print "[#{current_page}/#{total_pages}] Page #{page.id} (#{page.title}): "

          # Skip pages that already have ai_plaintext unless retranscribe mode
          if !retranscribe && page.ai_transcription.present?
            puts 'SKIPPED (already has AI plaintext)'
            overall_skip += 1
            next
          end

          # Call the interactor
          result = Page::FetchAiText.new(page: page, model: model, prompt: prompt).call

          if result.success?
            puts 'SUCCESS'
            overall_success += 1
          else
            puts "ERROR - #{result.message}"
            overall_error += 1
          end

          # Small delay to avoid rate limiting
          sleep(0.5)
        end
      end

      puts '=' * 80
      puts 'Collection transcription complete!'
      if retranscribe
        puts "Success: #{overall_success}, Errors: #{overall_error}"
      else
        puts "Success: #{overall_success}, Skipped: #{overall_skip}, Errors: #{overall_error}"
      end
    end
  end
end
