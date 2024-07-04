namespace :fromthepage do
  namespace :transkribus do
    desc 'Check outstanding Transkribus API requests'
    task check_outstanding_requests: :environment do |_t, _args|
      transkribus_username = ENV.fetch('TRANSKRIBUS_USERNAME', nil)
      transkribus_password = ENV.fetch('TRANSKRIBUS_PASSWORD', nil)
      if transkribus_username.nil? || transkribus_password.nil?
        print "TRANSKRIBUS_USERNAME and TRANSKRIBUS_PASSWORD must be set in the environment\n"
        return
      end

      ExternalApiRequest.where(engine: ExternalApiRequest::Engine::TRANSKRIBUS,
        status: ExternalApiRequest::Status::WAITING).each do |external_api_request|
        page = external_api_request.page
        page_processor = PageProcessor.new(page, external_api_request, transkribus_username, transkribus_password)
        page_processor.check_status_and_update_page
      end
    end

    desc 'Process an entire collection: collection_id, [all|unprocessed]'
    task :process_collection, [:collection_id, :page_filter, :model_id] => :environment do |_t, args|
      transkribus_username = ENV.fetch('TRANSKRIBUS_USERNAME', nil)
      transkribus_password = ENV.fetch('TRANSKRIBUS_PASSWORD', nil)
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
        collection = DocumentSet.where(id: args.collection_id.to_i).first if collection.nil?
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
        model_id = args.model_id.to_i
      end

      collection.pages.each do |page|
        next unless page_filter == 'all' || (page_filter == 'unprocessed' && !page.has_alto?)

        print "#{page.id} "
        page_processor = PageProcessor.new(page, nil, transkribus_username, transkribus_password, model_id)
        page_processor.begin_processing_page
      end
    end

    desc 'Process a work: work_id, [all|unprocessed]'
    task :process_work, [:work_id, :page_filter] => :environment do |_t, args|
      transkribus_username = ENV.fetch('TRANSKRIBUS_USERNAME', nil)
      transkribus_password = ENV.fetch('TRANSKRIBUS_PASSWORD', nil)
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
        next unless page_filter == 'all' || (page_filter == 'unprocessed' && !page.has_alto?)

        print "#{page.id} "
        page_processor = PageProcessor.new(page, nil, transkribus_username, transkribus_password)
        page_processor.begin_processing_page
      end
    end
  end
end
