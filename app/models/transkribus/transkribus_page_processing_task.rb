# == Schema Information
#
# Table name: page_processing_tasks
#
#  id                     :integer          not null, primary key
#  details                :text(65535)
#  position               :integer
#  status                 :string(255)
#  type                   :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  page_processing_job_id :integer          not null
#
# Indexes
#
#  index_page_processing_tasks_on_page_processing_job_id  (page_processing_job_id)
#
# Foreign Keys
#
#  fk_rails_...  (page_processing_job_id => page_processing_jobs.id)
#
module Transkribus
  module Response
    INSUFFICIENT_CREDITS = 429
    STILL_WAITING = 'waiting'
    ERRORED = 'error'
    CANCELED = 'canceled'
    READY = 'ready'
  end

  module Model
    TEXT_TITAN_I=51170
    ENGLISH_EAGLE_I=53042
  end

  class TranskribusPageProcessingTask < PageProcessingTask
    # # TODO get rid of external API request -- this is no longer needed since the 
    # def initialize(page, external_api_request=nil, transkribus_username=nil, transkribus_password=nil, model_id=Model::TEXT_TITAN_I)
    #   if external_api_request.nil?
    #     @external_api_request = ExternalApiRequest.new
    #     @external_api_request.user = page.collection.owner
    #     @external_api_request.collection = page.collection
    #     @external_api_request.page = page
    #     @external_api_request.work = page.work
    #     @external_api_request.params = {model_id: model_id}
    #     @external_api_request.engine = ExternalApiRequest::Engine::TRANSKRIBUS
    #     @external_api_request.status = ExternalApiRequest::Status::QUEUED
    #   else
    #     @external_api_request = external_api_request
    #   end
    # end

    def transkribus_username
      TRANSKRIBUS_USERNAME
    end

    def transkribus_password
      TRANSKRIBUS_PASSWORD
    end


    def process_page
      # if the status is queued, launch the processing job
      if self.status == Status::QUEUED
        self.status = Status::RUNNING
        self.save
        launch_processing_job
      elsif self.status == Status::RUNNING || self.status == Status::FAILED
        # no-op
        return
      elsif self.status == Status::WAITING
        # check the job
        # status needs to be specific to this task
        status = check_status
        if status == Response::INSUFFICIENT_CREDITS # also discovered in launch_processing_job
          # this account needs more Transkribus credits 
          self.status == Status::FAILED
          self.save
          return
        elsif status == Response::CANCELED
          # the user canceled the job in the Transkribus UI -- assume they don't want to spend more money
          self.status = Status::FAILED
          self.save
          return
        elsif status == Response::STILL_WAITING
          self.status = Status::WAITING
          self.save
        elsif status == Response::ERRORED
          self.status = Status::RETRY
          self.save
        elsif status == Response::READY
          fetch_alto
          self.status = Status::COMPLETED
          self.save
        end
      end
    end


    # TODO get rid of external API request -- this is no longer needed since the
    def launch_processing_job
      # first, call the transkribus api to submit the request
      model_id = self.ai_job.parameters[self.class.name]['model_id']
      submit_response = authorized_transkribus_request { submit_processing_request(page,model_id) }

      if submit_response.code != 200
        if submit_response.code == 429
          # this account needs more Transkribus credits
          self.details['error'] = submit_response.to_json
          self.status=Status::FAILED
          self.save!
          return Response::INSUFFICIENT_CREDITS
        else
          # there is some other error
          self.details['error'] = submit_response.to_json
          self.status=Status::FAILED
          self.save!
          return
        end
      end

      process_id = submit_response.parsed_response['processId']
      self.details['process_id'] = process_id
      self.status = Status::WAITING
      self.save!
    end

    def check_status
      process_id = self.details['process_id']
      status_response = authorized_transkribus_request { get_processing_status(process_id) }
      if status_response.code != 200
        if status_response.code == 404
          # transkribus has a possible bug where it returns a 404 when the process_id is finished
          # so we'll just assume that's what happened
          return Response::READY # is this really a good idea?
        else
          print "error getting status for process_id=#{process_id}\n#{status_response.to_json}\n"
          self.details['error'] = status_response.to_json
          return Response::ERRORED
        end
      else
        status = status_response.parsed_response['status']
        if status=='CANCELED'
          print "process_id=#{process_id} was canceled, probably in the Transkribus UI\n"
          self.details['error'] = "process_id=#{process_id} was canceled, probably in the Transkribus UI"
          @external_api_request.status = ExternalApiRequest::Status::FAILED
          @external_api_request.save!
          return
        elsif status=='FINISHED'
          return Response::READY
        else # there is probably a better status for this
          return Response::STILL_WAITING
        end  
      end
    end

    def fetch_alto
      process_id = self.details['process_id']
      alto_response = authorized_transkribus_request { get_processing_result(process_id) }
      alto = alto_response.body.force_encoding('UTF-8') # HTTParty doesn't thinks the response is ASCII-8BIT but it's actually UTF-8
      # write to the page
      page.alto_xml = alto
      page.save!
    end


  
  
    private
    def authorized_transkribus_request
      # takes a block with the actual request to be made
      response = yield
      # TODO: handle codes other than 200 and 401 -- currently non-401 assumes success
      if response.code == 401
        set_transkribus_token
        response = yield
      end
      return response
    end

    def submit_processing_request(page,model_id)
      request = {
        "config": {
          "textRecognition": {
            "htrId": model_id
          }
        },
        "image": {
          "imageUrl": page.image_url_for_download
        },
      }

      processing_request_url = "https://transkribus.eu/processing/v1/processes"

      # now send the request data to the url as a POST request
      response = HTTParty.post(processing_request_url,
        body: request.to_json,
        headers: { 
          'accept' => 'application/json', 
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{@access_token}" 
        }
      )
      pp response
      return response
    end


    # wrappers for the three Transkribus APIs
    def get_processing_result(process_id)
      # retrieve the result of the processing request
      result_request_url = "https://transkribus.eu/processing/v1/processes/#{process_id}/alto"
      # return the result
      response = HTTParty.get(result_request_url,
        headers: { 
          'accept' => 'application/xml', 
          'Content-Type' => 'application/xml',
          'Authorization' => "Bearer #{@access_token}" 
        })
      pp response
      return response
    end

    def get_processing_status(process_id)
      # retrieve the status of the processing
      status_request_url = "https://transkribus.eu/processing/v1/processes/#{process_id}"
      
      # use HTTParty to get the response
      response = HTTParty.get(status_request_url,
        headers: { 
          'accept' => 'application/json', 
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{@access_token}" 
        })
      pp response
      return response
    end




    def set_transkribus_token
      # if we are here, we have encountered a 401 error somewhere and need to get a new token
      # first try refreshing our token
      if @refresh_token
        # the refresh token may work but may be stale, so we need to try it first

        # Use refresh token to get a new access token when the old one has expired
        # curl --location --request POST 'https://account.readcoop.eu/auth/realms/readcoop/protocol/openid-connect/token' \
        # --header 'Content-Type: application/x-www-form-urlencoded' \
        # --data-urlencode grant_type=refresh_token \
        # --data-urlencode client_id=processing-api-client \
        # --data-urlencode refresh_token=$REFRESH_TOKEN # Use refresh token from authentication request. Replace your refresh token in case the response of this request contains a new one.
        refresh_token_url = "https://account.readcoop.eu/auth/realms/readcoop/protocol/openid-connect/token"
        response = HTTParty.post(refresh_token_url,
          body: {
            grant_type: "refresh_token",
            client_id: "processing-api-client",
            refresh_token: @refresh_token
          }
        )
        if response.code == 200
          parsed_response = response.parsed_response
          @access_token = parsed_response['access_token']
          @refresh_token = parsed_response['refresh_token']
          return
        else
          # Handle the error
          print "error refreshing token\n"
          pp response
        end
      end

      # if we are here, we need to get a new token
      # curl --location --request POST 'https://account.readcoop.eu/auth/realms/readcoop/protocol/openid-connect/token' \
      # --header 'Content-Type: application/x-www-form-urlencoded' \
      # --data-urlencode grant_type=password \
      # --data-urlencode username=$USERNAME \
      # --data-urlencode password=$PASSWORD \
      # --data-urlencode client_id=processing-api-client
      token_url = "https://account.readcoop.eu/auth/realms/readcoop/protocol/openid-connect/token"
      response = HTTParty.post(token_url,
        body: {
          grant_type: "password",
          username: transkribus_username,
          password: transkribus_password,
          client_id: "processing-api-client"
        }
      )
      if response.code == 200
        parsed_response = response.parsed_response
        @access_token = parsed_response['access_token']
        @refresh_token = parsed_response['refresh_token']
        return
      else
        # Handle the error
        print "error getting token for user/password combo\n"
        pp response
        return nil
      end
    end
  end
end
