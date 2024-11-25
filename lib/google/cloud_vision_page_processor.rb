require 'google/cloud/vision'

module Google
  module CloudVision
    
    class PageProcessor
      def setup_credentials
        if defined?(GCV_ENABLED) && GCV_ENABLED
          if !defined?(GCV_CREDENTIAL_FILE)
            raise "GCV_CREDENTIAL_FILE must point to a Google API credential file."
          end
            
          if !File.exist?(GCV_CREDENTIAL_FILE)
            raise "Google Cloud Vision credential file not found at #{GCV_CREDENTIAL_FILE}"
          end
    
          if !defined?(OCR_TRANSFORM_COMMAND) || OCR_TRANSFORM_COMMAND.blank?
            raise "OCR_TRANSFORM_COMMAND must be defined in config/initializers/01fromthepage.rb"
          end
    
          # To do -- move to initializer
          Google::Cloud::Vision.configure do |config|
            config.credentials = GCV_CREDENTIAL_FILE
            #Rails.root.join('config', 'google', 'gcv.json')
          end
        end
      end

      def initialize(page)
        @page = page
      end

      def process_page
        setup_credentials
        # Code to send the image to the GCV document processing API
        gcv_client = Google::Cloud::Vision.image_annotator
        # we want to send the image url, not the image itself
#        image_url = @page.image_url_for_download 
        image_url = 'https://fromthepage.com/images/uploaded/30154/page_0003.jpg'
        response = gcv_client.document_text_detection(image: image_url)
        # process the response

        # save the response to the page
        # pretty print the json TODO: remove this
        @page.gcv_json=JSON.pretty_generate(JSON.parse(response.to_json))

        # now generate the ALTO XML from the response
        # this is a shell command that runs a docker container
        # that converts the GCV JSON to ALTO XML
        # the ALTO XML is then saved to the page
        # hocr = `#{OCR_TRANSFORM_COMMAND} #{response.to_json}`

        
      end
    end
  end
end