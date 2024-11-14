VCR.configure do |c|
  c.ignore_localhost = true
  c.allow_http_connections_when_no_cassette = true
  c.hook_into :webmock
  c.cassette_library_dir = 'spec/http-mocks'

  c.default_cassette_options = { record: :new_episodes }
end
