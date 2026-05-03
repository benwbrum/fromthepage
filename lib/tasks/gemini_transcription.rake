namespace :fromthepage do
  namespace :gemini do
    desc 'Transcribe a single page using Gemini AI'
    task :transcribe_page, [:page_id, :model, :prompt_file] => :environment do |_t, args|
      unless args.page_id
        puts 'Usage: rake fromthepage:gemini:transcribe_page[page_id]'
        puts 'Example: rake fromthepage:gemini:transcribe_page[123]'
        puts 'Example: rake fromthepage:gemini:transcribe_page[123,gemini-3-flash-preview,prompt.txt]'
        exit 1
      end

      model = args.model
      prompt_file = args.prompt_file

      page = Page.find(args.page_id.to_i)
      user = User.find(page.collection.owner_user_id)

      puts "Initializing Gemini AI transcription for page ID: #{page.id} (#{page.title})"
      create_result = AiTranscription::Create.new(
        page: page,
        user: user,
        model: model,
        prompt_file: prompt_file,
        retranscribe: true
      ).call

      if !create_result.success?
        puts "Initialization ERROR - #{result.full_errors}\n#{result.full_errors.message}"
        exit 1
      end

      puts "Starting Gemini AI transcription for page ID: #{page.id} (#{page.title})"

      begin
        AiTranscription::GenerateJob.perform_now(user_id: user.id, ai_transcription_id: create_result.ai_transcription.id)

        puts 'Transcription SUCCESS'
      rescue StandardError => e
        puts "Transcription ERROR - #{e}\n#{e.message}"
      end
    end

    desc 'Transcribe all pages in a work using Gemini AI (pass "retranscribe" to overwrite existing)'
    task :transcribe_work, [:work_slug, :retranscribe, :model, :prompt_file] => :environment do |_t, args|
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

      user = User.find(work.collection.owner_user_id)

      prompt_file = args.prompt_file

      puts "Starting Gemini AI transcription for work: #{work.title}"
      puts "Mode: #{retranscribe ? 'RETRANSCRIBE (will overwrite existing)' : 'NORMAL (skips existing)'}"
      puts "Total pages: #{work.pages.count}"
      puts '=' * 80

      success_count = 0
      skip_count = 0
      error_count = 0

      work.pages.each_with_index do |page, index|
        print "[#{index + 1}/#{work.pages.count}] Page #{page.id} (#{page.title}): "

        puts "Initializing Gemini AI transcription for page ID: #{page.id} (#{page.title})"
        create_result = AiTranscription::Create.new(
          page: page,
          user: user,
          model: model,
          prompt_file: prompt_file,
          retranscribe: retranscribe
        ).call

        if !create_result.success? && create_result.full_errors.message.include?('AI Transcription generation is either in progress or completed!')
          # Skip pages that already have ai_plaintext unless retranscribe mode
          puts 'SKIPPED (already has AI plaintext)'
          skip_count += 1
          next
        elsif !create_result.success?
          raise create_result.full_errors
        end

        AiTranscription::GenerateJob.perform_now(user_id: user.id, ai_transcription_id: create_result.ai_transcription.id)

        puts 'SUCCESS'
        success_count += 1
      rescue StandardError => e
        puts "ERROR - #{e}\n#{e.message}"
        error_count += 1
      ensure
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
      collection = Collection::Lib::SetFriendlyFind.perform(id: id)

      raise 'Collection does not exist' if collection.nil?

      user = User.find(collection.owner_user_id)

      prompt_file = args.prompt_file

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

          puts "Initializing Gemini AI transcription for page ID: #{page.id} (#{page.title})"
          create_result = AiTranscription::Create.new(
            page: page,
            user: user,
            model: model,
            prompt_file: prompt_file,
            retranscribe: retranscribe
          ).call

          if !create_result.success? && create_result.full_errors.message.include?('AI Transcription generation is either in progress or completed!')
            # Skip pages that already have ai_plaintext unless retranscribe mode
            puts 'SKIPPED (already has AI plaintext)'
            overall_skip += 1
            next
          elsif !create_result.success?
            raise create_result.full_errors
          end

          AiTranscription::GenerateJob.perform_now(user_id: user.id, ai_transcription_id: create_result.ai_transcription.id)

          puts 'SUCCESS'
          overall_success += 1
        rescue StandardError => e
          puts "ERROR - #{e}\n#{e.message}"
          overall_error += 1
        ensure
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
