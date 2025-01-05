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
    ElasticUtil.reindex(Collection, 'ftp_collection');
    # Docsets are a special type of collection, intentionally using same index
    ElasticUtil.reindex(DocumentSet, 'ftp_collection');
    ElasticUtil.reindex(Page, 'ftp_page');
    ElasticUtil.reindex(User.where.not(owner: 0, account_type: 'staff'), 'ftp_user');
    ElasticUtil.reindex(Work.where.not(collection_id: 0), 'ftp_work');
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
