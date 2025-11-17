namespace :fromthepage do
  namespace :gemini do
    desc 'Transcribe all pages in a work using Gemini AI'
    task :transcribe_work, [:work_slug] => :environment do |_t, args|
      require 'gemini/text_transcriber'

      unless args.work_slug
        puts 'Usage: rake fromthepage:gemini:transcribe_work[work_slug]'
        puts 'Example: rake fromthepage:gemini:transcribe_work[my-work-slug]'
        exit 1
      end

      # Find work by ID or slug
      work = if args.work_slug.match?(/^\d+$/)
               Work.find(args.work_slug.to_i)
             else
               Work.friendly.find(args.work_slug)
             end

      puts "Starting Gemini AI transcription for work: #{work.title}"
      puts "Total pages: #{work.pages.count}"
      puts "=" * 80

      success_count = 0
      skip_count = 0
      error_count = 0

      work.pages.each_with_index do |page, index|
        print "[#{index + 1}/#{work.pages.count}] Page #{page.id} (#{page.title}): "

        # Skip pages that already have ai_plaintext
        if page.has_ai_plaintext?
          puts "SKIPPED (already has AI plaintext)"
          skip_count += 1
          next
        end

        # Call the interactor
        result = Page::FetchAiText.new(page: page).call

        if result.success?
          puts "SUCCESS"
          success_count += 1
        else
          puts "ERROR - #{result.message}"
          error_count += 1
        end

        # Small delay to avoid rate limiting
        sleep(0.5)
      end

      puts "=" * 80
      puts "Transcription complete!"
      puts "Success: #{success_count}, Skipped: #{skip_count}, Errors: #{error_count}"
    end

    desc 'Transcribe all pages in all works in a collection using Gemini AI'
    task :transcribe_collection, [:collection_slug] => :environment do |_t, args|
      require 'gemini/text_transcriber'

      unless args.collection_slug
        puts 'Usage: rake fromthepage:gemini:transcribe_collection[collection_slug]'
        puts 'Example: rake fromthepage:gemini:transcribe_collection[my-collection-slug]'
        exit 1
      end

      # Find collection by ID or slug
      collection = if args.collection_slug.match?(/^\d+$/)
                     Collection.find(args.collection_slug.to_i)
                   else
                     Collection.friendly.find(args.collection_slug)
                   end

      puts "Starting Gemini AI transcription for collection: #{collection.title}"
      puts "Total works: #{collection.works.count}"

      total_pages = collection.works.sum { |w| w.pages.count }
      puts "Total pages: #{total_pages}"
      puts "=" * 80

      overall_success = 0
      overall_skip = 0
      overall_error = 0
      current_page = 0

      collection.works.each do |work|
        puts "\nProcessing work: #{work.title} (#{work.pages.count} pages)"
        puts "-" * 80

        work.pages.each do |page|
          current_page += 1
          print "[#{current_page}/#{total_pages}] Page #{page.id} (#{page.title}): "

          # Skip pages that already have ai_plaintext
          if page.has_ai_plaintext?
            puts "SKIPPED (already has AI plaintext)"
            overall_skip += 1
            next
          end

          # Call the interactor
          result = Page::FetchAiText.new(page: page).call

          if result.success?
            puts "SUCCESS"
            overall_success += 1
          else
            puts "ERROR - #{result.message}"
            overall_error += 1
          end

          # Small delay to avoid rate limiting
          sleep(0.5)
        end
      end

      puts "=" * 80
      puts "Collection transcription complete!"
      puts "Success: #{overall_success}, Skipped: #{overall_skip}, Errors: #{overall_error}"
    end

    desc 'Force re-transcribe all pages in a work using Gemini AI (overwrites existing ai_plaintext)'
    task :retranscribe_work, [:work_slug] => :environment do |_t, args|
      require 'gemini/text_transcriber'

      unless args.work_slug
        puts 'Usage: rake fromthepage:gemini:retranscribe_work[work_slug]'
        puts 'Example: rake fromthepage:gemini:retranscribe_work[my-work-slug]'
        exit 1
      end

      # Find work by ID or slug
      work = if args.work_slug.match?(/^\d+$/)
               Work.find(args.work_slug.to_i)
             else
               Work.friendly.find(args.work_slug)
             end

      puts "Starting Gemini AI RE-transcription for work: #{work.title}"
      puts "WARNING: This will overwrite existing AI plaintext!"
      puts "Total pages: #{work.pages.count}"
      puts "=" * 80

      success_count = 0
      error_count = 0

      work.pages.each_with_index do |page, index|
        print "[#{index + 1}/#{work.pages.count}] Page #{page.id} (#{page.title}): "

        # Call the interactor
        result = Page::FetchAiText.new(page: page).call

        if result.success?
          puts "SUCCESS"
          success_count += 1
        else
          puts "ERROR - #{result.message}"
          error_count += 1
        end

        # Small delay to avoid rate limiting
        sleep(0.5)
      end

      puts "=" * 80
      puts "Re-transcription complete!"
      puts "Success: #{success_count}, Errors: #{error_count}"
    end

    desc 'Force re-transcribe all pages in all works in a collection using Gemini AI (overwrites existing ai_plaintext)'
    task :retranscribe_collection, [:collection_slug] => :environment do |_t, args|
      require 'gemini/text_transcriber'

      unless args.collection_slug
        puts 'Usage: rake fromthepage:gemini:retranscribe_collection[collection_slug]'
        puts 'Example: rake fromthepage:gemini:retranscribe_collection[my-collection-slug]'
        exit 1
      end

      # Find collection by ID or slug
      collection = if args.collection_slug.match?(/^\d+$/)
                     Collection.find(args.collection_slug.to_i)
                   else
                     Collection.friendly.find(args.collection_slug)
                   end

      puts "Starting Gemini AI RE-transcription for collection: #{collection.title}"
      puts "WARNING: This will overwrite existing AI plaintext!"
      puts "Total works: #{collection.works.count}"

      total_pages = collection.works.sum { |w| w.pages.count }
      puts "Total pages: #{total_pages}"
      puts "=" * 80

      overall_success = 0
      overall_error = 0
      current_page = 0

      collection.works.each do |work|
        puts "\nProcessing work: #{work.title} (#{work.pages.count} pages)"
        puts "-" * 80

        work.pages.each do |page|
          current_page += 1
          print "[#{current_page}/#{total_pages}] Page #{page.id} (#{page.title}): "

          # Call the interactor
          result = Page::FetchAiText.new(page: page).call

          if result.success?
            puts "SUCCESS"
            overall_success += 1
          else
            puts "ERROR - #{result.message}"
            overall_error += 1
          end

          # Small delay to avoid rate limiting
          sleep(0.5)
        end
      end

      puts "=" * 80
      puts "Collection re-transcription complete!"
      puts "Success: #{overall_success}, Errors: #{overall_error}"
    end
  end
end
