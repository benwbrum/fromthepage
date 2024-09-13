require 'json'
require 'elastic_util'

namespace :fromthepage do
  desc "Initialize Elasticsearch configuration and create indexes"
  task :es_init, [] => :environment do |t,args|
    client = ElasticUtil.get_client()
    # Template
    template_body = get_es_config(['schema', 'template.json'])
    client.indices.put_template(
      name: 'fromthepage',
      body: template_body
    )

    # Scripts
    script_src = get_es_config(['scripts', 'multilingual_content.painless'], false)
    script_def = {
      script: {
        lang: 'painless',
        source: script_src
      }
    }
    client.put_script(
      id: 'multilingual_content',
      body: script_def
    )
   
    # Pipelines
    pipeline_body = get_es_config(['pipeline', 'multilingual.json'])
    client.ingest.put_pipeline(
      id: 'multilingual',
      body: pipeline_body
    )
    
    # Index schema
    collection_body = get_es_config(['schema', 'collection.json'])
    page_body = get_es_config(['schema', 'page.json'])
    user_body = get_es_config(['schema', 'user.json'])
    work_body = get_es_config(['schema', 'work.json'])

    client.indices.create(index: 'ftp_collection', body: collection_body)
    client.indices.create(index: 'ftp_page', body: page_body)
    client.indices.create(index: 'ftp_user', body: user_body)
    client.indices.create(index: 'ftp_work', body: work_body)

    puts('Task complete, check status codes for errors.')
  end

  desc "Delete all configuration and indices created by init"
  task :es_reset, [] => :environment do |t,args|
    client = ElasticUtil.get_client()

    client.indices.delete_template(name: 'fromthepage')
    client.ingest.delete_pipeline(id: 'multilingual')
    client.delete_script(id: 'multilingual_content')

    client.indices.delete(index: 'ftp_collection')
    client.indices.delete(index: 'ftp_page')
    client.indices.delete(index: 'ftp_user')
    client.indices.delete(index: 'ftp_work')
  end

  desc "Reindex everything into elasticsearch"
  task :es_reindex, [] => :environment do |t,args|
    client = ElasticUtil.get_client()

    Page.find_in_batches(batch_size: 1000) do |batch|
      bulk_body = []
      batch.each do |page|
        bulk_body.push(
          ElasticUtil.gen_bulk_action('ftp_page', page.as_indexed_json())
        )
      end

      client.bulk(body: bulk_body, refresh: false)
    end

    client.indices.refresh(index: 'ftp_page')

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

end
