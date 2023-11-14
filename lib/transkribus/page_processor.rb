class PageProcessor

  # factory method
  def self.process_page(page)
    # are any page processors already processing this page?
    if page.external_api_requests.where(engine: ExternalApiRequest::Engine::TRANSKRIBUS, status: ExternalApiRequest::Status.running).exists?
      return false
    end

    # create a new page processor
    page_processor = PageProcessor.new(page)
    page_processor.submit!
  end

  def initialize(page, external_api_request=nil)
    @page = page
    if external_api_request.nil?
      @external_api_request = ExternalApiRequest.new
      @external_api_request.user = User.current_user
      @external_api_request.collection = page.collection
      @external_api_request.page = page
      @external_api_request.work = page.work
      @external_api_request.engine = ExternalApiRequest::Engine::TRANSKRIBUS
      @external_api_request.status = ExternalApiRequest::Status::QUEUED
    else
      @external_api_request = external_api_request
    end
  end


  # for now we're going to handle the logic here, rather than abstracting any of it to the external api request
  # consider generalizing this when we have more requests
  def submit_process
    @external_api_request.save!
    rake_call = "#{RAKE} fromthepage:run_transkribus_processing[#{@external_api_request.id}]  --trace >> #{log_file} 2>&1 &"

    # Nice-up the rake call if settings are present
    rake_call = "nice -n #{NICE_RAKE_LEVEL} " << rake_call if NICE_RAKE_ENABLED

    Rails.logger.info rake_call
    system(rake_call)
  end

  def run_process
    # we should have both a page and an external_api_request
    # first, call the transkribus api to submit the request
    binding.pry
    @external_api_request.status = ExternalApiRequest::Status::RUNNING
    @external_api_request.save!
    process_id = submit_processing_request(@page)

    @external_api_request.params = {process_id: process_id}.to_json
    @external_api_request.status = ExternalApiRequest::Status::WAITING
    @external_api_request.save!

    # then, check the status of the request until it's done
    status=nil
    iteration = 0    
    while status != 'FINISHED' do
      status = get_processing_status(process_id)
      sleep (2+iteration*5).seconds
      iteration += 1
      # break out of the loop if the iteration exceeds 1000
      break if iteration > 1000
    end

    # then, retrieve the result of the request
    alto = get_processing_result(process_id)

    # write to the page
    page.alto_xml = alto

  end


  private
  def log_file
    "/tmp/fromthepage_rake.log"
  end




  def process_page(page)
    # fetch the API key from the configuration
    api_key = TRANSKRIBUS_API_KEY

    # fetch a URL for the page's image
    page_image_url = XXXxX

    process_id = submit_processing_request(page)
    # store it on the object somehow?  Somewhere?
  end


  private
  # wrappers for the three Transkribus APIs
  def get_processing_result(process_id)
    # retrieve the result of the processing request
    result_request_url = "https://transkribus.eu/processing/v1/processes/#{process_id}/alto"
    # return the result
    response = HTTParty.get(result_request_url,
      headers: { 
        'accept' => 'application/json', 
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{TRANSKRIBUS_ACCESS_TOKEN}" 
      })
    binding.pry
    if response.code == 200
      parsed_response = response.parsed_response
      return parsed_response
    else
      # Handle the error
      return nil
    end
  end

  def get_processing_status(process_id)
    # retrieve the status of the processing
    status_request_url = "https://transkribus.eu/processing/v1/processes/#{process_id}"
    
    # use HTTParty to get the response
    response = HTTParty.get(status_request_url,
      headers: { 
        'accept' => 'application/json', 
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{TRANSKRIBUS_ACCESS_TOKEN}" 
      })
    binding.pry
    if response.code == 200
      parsed_response = response.parsed_response
      return parsed_response['status']
    else
      # Handle the error
      return nil
    end
  end

  def submit_processing_request(page)
    binding.pry
    request = {
      "config": {
        "textRecognition": {
          "htrId": 51170 # text titan
        }
      },
      "image": {
        "imageUrl": "https://fromthepage.com#{page.image_url_for_download}"
      },
    }

    binding.pry
    processing_request_url = "https://transkribus.eu/processing/v1/processes"

    # now send the request data to the url as a POST request
    response = HTTParty.post(processing_request_url,
      body: request.to_json,
      headers: { 
        'accept' => 'application/json', 
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{TRANSKRIBUS_ACCESS_TOKEN}" 
      }
    )
    binding.pry

    # Process your response if successful
    if response.code == 200
      parsed_response = response.parsed_response
      return parsed_response['processId']
    else
      # Handle the error
      return nil
    end

  end

end