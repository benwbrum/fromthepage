require 'net/http'
require 'json'

class HttpClient

    def initialize(baseURL, headers = {}, responseFormat = 'json')
        @baseURL = baseURL
        @headers = headers
        @responseFormat = responseFormat
    end

    def do_post(path, params = {}, bodyParams = {})
        send_request(Net::HTTP::Post, path, params, bodyParams)
    end

    def do_get(path, params = {})
        send_request(Net::HTTP::Get, path, params)
    end

    def do_put(path, params = {}, bodyParams = {})
        send_request(Net::HTTP::Put, path, params, bodyParams)
    end

    def do_delete(path, params = {}, bodyParams = {})
        send_request(Net::HTTP::Delete, path, params, bodyParams)
    end

    private
    def send_request(methodClass, path, params = {}, bodyParams = {})
        uri=URI(@baseURL)
        uri.path=path
        uri.query=URI.encode_www_form(params)

        req = methodClass.new(uri)
        # Set headers in request
        headers = @headers.collect{|k,v| [k.to_s, v]}.to_h
        headers.each do |key, value|
            req[key] = value
        end

        bodyParams.is_a?(String) ? req.body = bodyParams : req.set_form_data(bodyParams)

        res = Net::HTTP.start(uri.hostname,uri.port, :use_ssl => uri.scheme == 'https') {|http|
            http.request(req)
        }
        process_response(res, @responseFormat)
    end

    def process_response(response, processFormat)
      case response
        when Net::HTTPSuccess
          processFormat == 'json' ? JSON.parse(response.body, object_class: OpenStruct) : {'ok' => true, 'data' => response } 
        when Net::HTTPUnauthorized
          { 'ok' => false, 'error' => "#{response.message}: username and password set and correct?"}
        when Net::HTTPServerError
          { 'ok' => false, 'error' => "#{response.message}: try again later?"}
        else
          { 'ok' => false, 'error' => response.message}
      end
    end
end
