require 'net/http'

class HttpClient

    def initialize(baseURL,headers = {})
        @baseURL = baseURL
        @headers = headers
    end

    private
    def do_post(path, params = {}, bodyParams = {})
        send_request(Net::HTTP::Post, path, params, bodyParams)
    end

    private
    def do_get(path, params = {})
        send_request(Net::HTTP::Get, path, params)
    end

    private
    def do_put(path, params = {}, bodyParams = {})
        send_request(Net::HTTP::Put, path, params, bodyParams)
    end

    private
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
        @headers.each do |key, value|
            req[key] = value
        end
        req.set_form_data(bodyParams)

        res = Net::HTTP.start(uri.hostname,uri.port, :use_ssl => uri.scheme == 'https') {|http|
            http.request(req)
        }
        process_response(res)
    end

    private
    def process_response(response)
      case response
        when Net::HTTPSuccess
          JSON.parse(response.body, object_class: OpenStruct)
        when Net::HTTPUnauthorized
          {'error' => "#{response.message}: username and password set and correct?"}
        when Net::HTTPServerError
          {'error' => "#{response.message}: try again later?"}
        else
          {'error' => response.message}
      end
    end
end
