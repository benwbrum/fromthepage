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
        image_url = @page.image_url_for_download 
        response = gcv_client.document_text_detection(image: image_url)
        # save the response to the page
        if response.responses.first.error
          # print the error to STDERR but do not exit.  Also print the image_url
          STDERR.puts "Error processing image: #{image_url}.  GCV error message:"
          STDERR.puts response.responses.first.error.message
          return
        end


        # pretty print the json to get eround problems in ocr-transform
        @page.gcv_json=JSON.pretty_generate(JSON.parse(response.to_json))

        # now generate the ALTO XML from the response
        # this is a shell command that runs a docker container
        # that converts the GCV JSON to ALTO XML
        # the ALTO XML is then saved to the page
        cmd = OCR_TRANSFORM_COMMAND
        # make a system call with cmd, piping the response to the command

        stdout, stderr, status = Open3.capture3(cmd, stdin_data: @page.gcv_json)

        if status.success?
          @page.alto_xml = stdout
        else
          raise "Error executing ocr-transform: #{stderr}"
        end
        
      end


      def self.plaintext_from_gcv_json(gcv_json)
        # convert the GCV JSON string to plaintext
        gcv = JSON.parse(gcv_json)['responses'][0]
        plaintext = gcv['fullTextAnnotation']['text']
      end
    end
  end
end