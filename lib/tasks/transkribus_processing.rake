namespace :fromthepage do
  namespace :transkribus do

    desc "Check outstanding Transkribus API requests"
    task :check_outstanding_requests => :environment do |t,args|
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

    desc "Process an entire collection: collection_id, [all|unprocessed]"
    task :process_collection, [:collection_id, :page_filter] => :environment do |t,args|
      transkribus_username = ENV['TRANSKRIBUS_USERNAME']
      transkribus_password = ENV['TRANSKRIBUS_PASSWORD']
      if transkribus_username.nil? || transkribus_password.nil?
        print "TRANSKRIBUS_USERNAME and TRANSKRIBUS_PASSWORD must be set in the environment\n"
        return
      end
      if args.collection_id.match(/^\d+$/)
        collection = Collection.find args.collection_id.to_i
      else
        collection = Collection.find args.collection_id
      end
      if args.page_filter.nil?
        page_filter = "all"
      else
        page_filter = args.page_filter
      end

      collection.pages.each do |page|
        if page_filter=='all' || (page_filter=='unprocessed' && !page.has_alto?)
          print "#{page.id} "
          page_processor = PageProcessor.new(page, nil, transkribus_username, transkribus_password)
          page_processor.begin_processing_page
        end
      end
    end

    desc "Process a work: work_id, [all|unprocessed]"
    task :process_work, [:work_id, :page_filter] => :environment do |t,args|
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
        page_filter = "all"
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

  end
end