namespace :fromthepage do

  desc "Check outstanding Transkribus API requests"
  task :check_outstanding_transkribus_requests => :environment do |t,args|
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

  desc "Process an entire collection"
  task :transkribus_process_collection, [:collection_id] => :environment do |t,args|
    transkribus_username = ENV['TRANSKRIBUS_USERNAME']
    transkribus_password = ENV['TRANSKRIBUS_PASSWORD']
    if transkribus_username.nil? || transkribus_password.nil?
      print "TRANSKRIBUS_USERNAME and TRANSKRIBUS_PASSWORD must be set in the environment\n"
      return
    end
    collection = Collection.find args.collection_id.to_i
    collection.pages.each do |page|
      page_processor = PageProcessor.new(page, nil, transkribus_username, transkribus_password)
      page_processor.begin_processing_page
    end
  end

end
