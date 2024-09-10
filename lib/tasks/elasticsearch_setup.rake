require 'elasticsearch'
require 'json'

namespace :fromthepage do
  desc "Initialize Elasticsearch configuration and create indexes"
  task :es_init, [] => :environment do |t,args|
    client = get_es_client()
    # Template
    template_body = get_es_config(['schema', 'template.json'])
    resp = client.indices.put_template(
      name: 'fromthepage',
      body: template_body
    )
    log_resp('adding index template', resp)

    # Scripts
    script_src = get_es_config(['scripts', 'multilingual_content.painless'], false)
    script_def = {
      script: {
        lang: 'painless',
        source: script_src
      }
    }
    resp = client.put_script(
      id: 'multilingual_content',
      body: script_def
    )
    log_resp('adding painless script', resp)
   
    # Pipelines
    pipeline_body = get_es_config(['pipeline', 'multilingual.json'])
    resp = client.ingest.put_pipeline(
      id: 'multilingual',
      body: pipeline_body
    )
    log_resp('creating pipeline', resp)
    
    # Index schema
    collection_body = get_es_config(['schema', 'collection.json'])
    page_body = get_es_config(['schema', 'page.json'])
    user_body = get_es_config(['schema', 'user.json'])
    work_body = get_es_config(['schema', 'work.json'])

    resp = client.indices.create(index: 'ftp_collection', body: collection_body)
    log_resp('creating collection index', resp)

    resp = client.indices.create(index: 'ftp_page', body: page_body)
    log_resp('creating page index', resp)

    resp = client.indices.create(index: 'ftp_user', body: user_body)
    log_resp('creating user index', resp)

    resp = client.indices.create(index: 'ftp_work', body: work_body)
    log_resp('creating work index', resp)

    puts('Task complete, check status codes for errors.')
  end

  def get_es_config(target, parse = true)
    base_path = [Rails.root, 'lib', 'elastic']
    src = File.read(File.join(base_path + target))
    
    if !parse
      return src
    else
      return JSON.parse(src)
    end
  end

  def get_es_client()
    cloud_id = ENV['ELASTIC_CLOUD_ID']
    api_key = ENV['ELASTIC_API_KEY']

    return Elasticsearch::Client.new(
      cloud_id: cloud_id,
      api_key: api_key
    )
  end

  def log_resp(type, resp)
    puts("Tried #{type}, status code: #{resp}")
  end

end
