VCR.configure do |c|
  c.ignore_localhost = true
  c.allow_http_connections_when_no_cassette = false
  c.hook_into :webmock
  c.cassette_library_dir = 'spec/http-mocks'
end
