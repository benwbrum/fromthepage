#!/usr/bin/env ruby
# frozen_string_literal: true

# batch_upload.rb - Batch upload zipfiles to a FromThePage collection via the API.
#
# This script does NOT depend on the Rails stack and uses only Ruby standard library.
#
# Usage:
#   ruby script/batch_upload.rb [options] <folder>
#
# Options:
#   --server URL          Base URL of the FromThePage server (required)
#   --api-key KEY         API key for authentication (required)
#   --collection-slug SLUG  Target collection or document set slug (required)
#   --ocr                 Enable OCR on uploaded documents
#   --preserve-titles     Preserve titles from uploaded documents
#   --generate-ai-draft   Generate AI draft on uploaded documents
#   --recursive           Recursively search subdirectories for zip files
#   --poll-interval N     Seconds between status polls (default: 60, minimum: 60)
#   --help                Show this help message
#
# Example:
#   ruby script/batch_upload.rb \
#     --server https://fromthepage.com \
#     --api-key myapikey123 \
#     --collection-slug my-collection \
#     --recursive \
#     /path/to/zipfiles

require 'net/http'
require 'uri'
require 'json'
require 'optparse'
require 'securerandom'

MIN_POLL_INTERVAL = 60

def parse_options
  options = {
    server: nil,
    api_key: nil,
    collection_slug: nil,
    ocr: false,
    preserve_titles: false,
    generate_ai_draft: false,
    recursive: false,
    poll_interval: MIN_POLL_INTERVAL
  }

  parser = OptionParser.new do |opts|
    opts.banner = "Usage: ruby #{File.basename($PROGRAM_NAME)} [options] <folder>"

    opts.on('--server URL', 'Base URL of the FromThePage server (required)') do |v|
      options[:server] = v.chomp('/')
    end

    opts.on('--api-key KEY', 'API key for authentication (required)') do |v|
      options[:api_key] = v
    end

    opts.on('--collection-slug SLUG', 'Target collection or document set slug (required)') do |v|
      options[:collection_slug] = v
    end

    opts.on('--ocr', 'Enable OCR on uploaded documents') do
      options[:ocr] = true
    end

    opts.on('--preserve-titles', 'Preserve titles from uploaded documents') do
      options[:preserve_titles] = true
    end

    opts.on('--generate-ai-draft', 'Generate AI draft on uploaded documents') do
      options[:generate_ai_draft] = true
    end

    opts.on('--recursive', 'Recursively search subdirectories for zip files') do
      options[:recursive] = true
    end

    opts.on('--poll-interval N', Integer, "Seconds between status polls (default: #{MIN_POLL_INTERVAL}, minimum: #{MIN_POLL_INTERVAL})") do |v|
      options[:poll_interval] = [v, MIN_POLL_INTERVAL].max
    end

    opts.on('--help', 'Show this help message') do
      puts opts
      exit
    end
  end

  parser.parse!

  if ARGV.empty?
    warn 'Error: a folder argument is required'
    warn parser
    exit 1
  end

  options[:folder] = ARGV.shift

  %w[server api_key collection_slug].each do |required|
    next if options[required.to_sym]

    warn "Error: --#{required.tr('_', '-')} is required"
    warn parser
    exit 1
  end

  unless Dir.exist?(options[:folder])
    warn "Error: folder '#{options[:folder]}' does not exist"
    exit 1
  end

  options
end

def find_zip_files(folder, recursive)
  pattern = recursive ? File.join(folder, '**', '*.zip') : File.join(folder, '*.zip')
  Dir.glob(pattern).sort
end

def upload_file(server, api_key, collection_slug, file_path, options)
  uri = URI("#{server}/api/v1/document_upload/#{collection_slug}")
  boundary = "----BatchUploadBoundary#{SecureRandom.hex(16)}"

  body_parts = []

  # Build multipart form fields
  body_parts << "--#{boundary}\r\nContent-Disposition: form-data; name=\"ocr\"\r\n\r\n#{options[:ocr] ? 'true' : 'false'}"
  body_parts << "--#{boundary}\r\nContent-Disposition: form-data; name=\"preserve_titles\"\r\n\r\n#{options[:preserve_titles] ? 'true' : 'false'}"
  body_parts << "--#{boundary}\r\nContent-Disposition: form-data; name=\"generate_ai_draft\"\r\n\r\n#{options[:generate_ai_draft] ? 'true' : 'false'}"

  file_content = File.binread(file_path)
  filename = File.basename(file_path)
  body_parts << "--#{boundary}\r\nContent-Disposition: form-data; name=\"file\"; filename=\"#{filename}\"\r\nContent-Type: application/zip\r\n\r\n#{file_content}"
  body_parts << "--#{boundary}--"

  body = body_parts.join("\r\n")

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == 'https'
  http.read_timeout = 300

  request = Net::HTTP::Post.new(uri.request_uri)
  request['Authorization'] = "Bearer #{api_key}"
  request['Content-Type'] = "multipart/form-data; boundary=#{boundary}"
  request.body = body

  response = http.request(request)

  case response.code.to_i
  when 202
    JSON.parse(response.body)
  else
    raise "Upload failed (HTTP #{response.code}): #{response.body}"
  end
end

def poll_status(server, api_key, document_upload_id, poll_interval)
  uri = URI("#{server}/api/v1/document_upload/#{document_upload_id}/status")

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == 'https'

  request = Net::HTTP::Get.new(uri.request_uri)
  request['Authorization'] = "Bearer #{api_key}"

  loop do
    response = http.request(request)

    unless response.code.to_i == 200
      raise "Status check failed (HTTP #{response.code}): #{response.body}"
    end

    data = JSON.parse(response.body)
    status = data['status']

    puts "  Status: #{status}"

    case status
    when 'finished', 'error'
      return data
    else
      sleep poll_interval
    end
  end
end

def run
  options = parse_options
  zip_files = find_zip_files(options[:folder], options[:recursive])

  if zip_files.empty?
    puts "No zip files found in '#{options[:folder]}'"
    exit 0
  end

  puts "Found #{zip_files.length} zip file(s) to upload"
  puts "Server:          #{options[:server]}"
  puts "Collection slug: #{options[:collection_slug]}"
  puts "Poll interval:   #{options[:poll_interval]}s"
  puts

  zip_files.each_with_index do |zip_file, index|
    puts "[#{index + 1}/#{zip_files.length}] Uploading: #{zip_file}"

    begin
      result = upload_file(
        options[:server],
        options[:api_key],
        options[:collection_slug],
        zip_file,
        options
      )

      document_upload_id = result['id']
      puts "  Upload started (ID: #{document_upload_id})"

      final = poll_status(options[:server], options[:api_key], document_upload_id, options[:poll_interval])

      if final['status'] == 'finished'
        puts "  Upload complete"
      else
        puts "  Upload ended with status: #{final['status']}"
      end
    rescue StandardError => e
      warn "  Error: #{e.message}"
    end

    puts
  end

  puts "All uploads processed."
end

run
