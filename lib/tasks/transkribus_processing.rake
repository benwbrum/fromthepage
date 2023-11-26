namespace :fromthepage do

  desc "Run a Transkribus Processing API call"
  task :run_transkribus_processing, [:external_api_request_id] => :environment do |t,args|
    require "#{Rails.root}/app/helpers/error_helper"

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
    page_processor = PageProcessor.new(page, external_api_request)

    page_processor.run_process

    if page_processor.status == ExternalApiRequest::Status::COMPLETED
      print "page_processor completed successfully\n"
    else
      print "page_processor failed\n"
    end
  end
end