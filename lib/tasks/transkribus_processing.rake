namespace :fromthepage do

  desc "Run a Transkribus Processing API call"
  task :run_transkribus_processing, [:external_api_request_id] => :environment do |t,args|
    require "#{Rails.root}/app/helpers/error_helper"

    # read TRANSKRIBUS_USERNAME and TRANSKRIBUS_PASSWORD from the environment and error if they are not set
    transkribus_username = ENV['TRANSKRIBUS_USERNAME']
    transkribus_password = ENV['TRANSKRIBUS_PASSWORD']
    if transkribus_username.nil? || transkribus_password.nil?
      print "TRANSKRIBUS_USERNAME and TRANSKRIBUS_PASSWORD must be set in the environment\n"
      return
    end

    external_api_request_id = args.external_api_request_id
    print "fetching external_api_request with ID=#{external_api_request_id}\n"
    external_api_request = ExternalApiRequest.find external_api_request_id
    page = external_api_request.page
    # verify that this is a of the correct type/engine and has a valid page
    if external_api_request.engine != ExternalApiRequest::Engine::TRANSKRIBUS || page.nil?
      print "external_api_request is not a Transkribus request or does not have a valid page\n"
      return
    end

    print "found external_api_request for \n\tuser=#{external_api_request.user.login}, \n"
    page_processor = PageProcessor.new(page, external_api_request, transkribus_username, transkribus_password)

    page_processor.run_process

    
    external_api_request = ExternalApiRequest.find external_api_request_id
    if external_api_request.status == ExternalApiRequest::Status::COMPLETED
      print "page_processor completed successfully\n"
    else
      print "page_processor failed\n"
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
      PageProcessor.process_page(page, transkribus_username, transkribus_password)
    end
  end

end
