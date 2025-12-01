namespace :fromthepage do
  namespace :transkribus do
    desc 'Check outstanding Transkribus API requests'
    task check_outstanding_requests: :environment do |t, args|
      transkribus_username = ENV['TRANSKRIBUS_USERNAME']
      transkribus_password = ENV['TRANSKRIBUS_PASSWORD']
      if transkribus_username.nil? || transkribus_password.nil?
        print "TRANSKRIBUS_USERNAME and TRANSKRIBUS_PASSWORD must be set in the environment\n"
        return
      end

      ExternalApiRequest.where(engine: ExternalApiRequest::Engine::TRANSKRIBUS, status: ExternalApiRequest::Status::WAITING).each do |external_api_request|
        page = external_api_request.page
        page_processor = PageProcessor.new(page, external_api_request, transkribus_username, transkribus_password)
        page_processor.check_status_and_update_page
      end
    end

    desc 'Process an entire collection: collection_id, [all|unprocessed]'
    task :process_collection, [:collection_id, :page_filter, :model_id] => :environment do |t, args|
      transkribus_username = ENV['TRANSKRIBUS_USERNAME']
      transkribus_password = ENV['TRANSKRIBUS_PASSWORD']
      if transkribus_username.nil? || transkribus_password.nil?
        print "TRANSKRIBUS_USERNAME and TRANSKRIBUS_PASSWORD must be set in the environment\n"
        exit
      end
      if args.collection_id.match(/^\d+$/)
        collection = Collection.where(id: args.collection_id.to_i).first
      else
        collection = Collection.where(slug: args.collection_id).first
      end
      if collection.nil?
        collection = DocumentSet.where(slug: args.collection_id).first
        if collection.nil?
          collection = DocumentSet.where(id: args.collection_id.to_i).first
        end
      end
      if collection.nil?
        print "Collection or Document Set not found\n"
        exit
      end


      if args.page_filter.nil?
        page_filter = 'all'
      else
        page_filter = args.page_filter
      end

      if args.model_id.blank?
        model_id = PageProcessor::Model::TEXT_TITAN_I
      else
        model_id=args.model_id.to_i
      end


      collection.pages.each do |page|
        if page_filter=='all' || (page_filter=='unprocessed' && !page.has_alto?)
          print "#{page.id} "
          page_processor = PageProcessor.new(page, nil, transkribus_username, transkribus_password, model_id)
          page_processor.begin_processing_page
        end
      end
    end

    desc 'Process a work: work_id, [all|unprocessed]'
    task :process_work, [:work_id, :page_filter] => :environment do |t, args|
      transkribus_username = ENV['TRANSKRIBUS_USERNAME']
      transkribus_password = ENV['TRANSKRIBUS_PASSWORD']
      if transkribus_username.nil? || transkribus_password.nil?
        print "TRANSKRIBUS_USERNAME and TRANSKRIBUS_PASSWORD must be set in the environment\n"
        return
      end
      if args.work_id.match(/^\d+$/)
        work = Work.find args.work_id.to_i
      else
        work = Work.find args.work_id
      end
      if args.page_filter.nil?
        page_filter = 'all'
      else
        page_filter = args.page_filter
      end

      work.pages.each do |page|
        if page_filter=='all' || (page_filter=='unprocessed' && !page.has_alto?)
          print "#{page.id} "
          page_processor = PageProcessor.new(page, nil, transkribus_username, transkribus_password)
          page_processor.begin_processing_page
        end
      end
    end

    desc 'Find and report pages with invalid ALTO XML files'
    task find_invalid_alto: :environment do |t, args|
      puts "Scanning for pages with invalid ALTO XML files..."
      
      invalid_count = 0
      total_checked = 0
      
      Page.find_each do |page|
        # Check if there's an ALTO file on disk
        alto_file = File.join(Rails.root, 'public', 'text', page.work_id.to_s, "#{page.id}_alto.xml")
        next unless File.exist?(alto_file)
        
        total_checked += 1
        
        # Check if the ALTO file is valid
        unless page.valid_alto?
          invalid_count += 1
          content_preview = File.read(alto_file)[0..200]
          puts "Page #{page.id} (Work #{page.work_id}): Invalid ALTO XML"
          puts "  Preview: #{content_preview.gsub("\n", ' ')}"
          begin
            puts "  URL: #{Rails.application.routes.url_helpers.transcribe_page_path(page_id: page.id)}"
          rescue StandardError => e
            Rails.logger.warn("Unable to generate URL for page #{page.id}: #{e.message}")
          end
          puts ""
        end
      end
      
      puts "\nSummary:"
      puts "  Total pages checked: #{total_checked}"
      puts "  Invalid ALTO files found: #{invalid_count}"
    end

    desc 'Clean up invalid ALTO XML files for a collection or work'
    task :cleanup_invalid_alto, [:collection_id] => :environment do |t, args|
      if args.collection_id.nil?
        puts "Please provide a collection_id or work_id"
        puts "Usage: rake fromthepage:transkribus:cleanup_invalid_alto[collection_id]"
        exit
      end

      pages = []
      
      if args.collection_id.match(/^\d+$/)
        collection = Collection.where(id: args.collection_id.to_i).first
      else
        collection = Collection.where(slug: args.collection_id).first
      end
      
      if collection
        pages = collection.pages
        puts "Cleaning up invalid ALTO files for collection: #{collection.title}"
      else
        # Try as work_id
        work = Work.find_by(id: args.collection_id.to_i)
        if work
          pages = work.pages
          puts "Cleaning up invalid ALTO files for work: #{work.title}"
        else
          puts "Collection or Work not found"
          exit
        end
      end
      
      cleaned_count = 0
      failed_requests_reset = 0
      
      pages.each do |page|
        alto_file = File.join(Rails.root, 'public', 'text', page.work_id.to_s, "#{page.id}_alto.xml")
        next unless File.exist?(alto_file)
        
        unless page.valid_alto?
          puts "Deleting invalid ALTO file for page #{page.id}"
          page.delete_alto
          cleaned_count += 1
          
          # Also reset any failed external API requests for this page so they can be retried
          failed_requests = page.external_api_requests.where(
            engine: ExternalApiRequest::Engine::TRANSKRIBUS,
            status: [ExternalApiRequest::Status::FAILED, ExternalApiRequest::Status::COMPLETED]
          )
          
          failed_requests.each do |request|
            request.update(status: ExternalApiRequest::Status::QUEUED, params: {})
            failed_requests_reset += 1
          end
        end
      end
      
      puts "\nSummary:"
      puts "  Invalid ALTO files deleted: #{cleaned_count}"
      puts "  Failed API requests reset: #{failed_requests_reset}"
      puts "\nYou can now reprocess these pages using:"
      if collection
        puts "  rake fromthepage:transkribus:process_collection[#{args.collection_id},unprocessed]"
      else
        puts "  rake fromthepage:transkribus:process_work[#{args.collection_id},unprocessed]"
      end
    end
  end
end
