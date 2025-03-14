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

    client.indices.create(index: ElasticUtil::Index::COLLECTION,
                          body: collection_body)
    client.indices.create(index: ElasticUtil::Index::PAGE,
                          body: page_body)
    client.indices.create(index: ElasticUtil::Index::USER,
                          body: user_body)
    client.indices.create(index: ElasticUtil::Index::WORK,
                          body: work_body)

    puts('Task complete, check status codes for errors.')
  end

  desc "Report on the stats of the current indices"
  task :es_stats, [] => :environment do |t,args|
    client = ElasticUtil.get_client()

    resp = client.cat.indices(format: 'json')
    print "Current index stats:\n"
    current_indices = resp.select{|row| ElasticUtil::Index::ALL.include? row['index']}
    current_indices.each do |row|
      print "#{row['index']}:\t#{row['health']}\t#{row['status']}\t#{row['docs.count']} documents\n"
    end
    
    print "\nAll index stats:\n"
    resp.each do |row|
      unless row['index'].match(/^\./) || ElasticUtil::Index::ALL.include?(row['index'])
        print "#{row['index']}:\t#{row['health']}\t#{row['status']}\t#{row['docs.count']} documents\n"
      end
    end

  end  

  desc "Delete all configuration and indices created by init"
  task :es_reset, [] => :environment do |t,args|
    client = ElasticUtil.get_client()

    client.indices.delete_template(name: 'fromthepage')
    client.ingest.delete_pipeline(id: 'multilingual')
    client.delete_script(id: 'multilingual_content')

    client.indices.delete(index: ElasticUtil::Index::COLLECTION)
    client.indices.delete(index: ElasticUtil::Index::PAGE)
    client.indices.delete(index: ElasticUtil::Index::USER)
    client.indices.delete(index: ElasticUtil::Index::WORK)
  end

  desc "Reindex everything into elasticsearch"
  task :es_reindex, [:models] => :environment do |t,args|
    # look in the arguments for specific models to reindex
    # if none are provided, reindex everything
    if args[:models].blank?
      models=[:collection, :document_set, :page, :user, :work]
    else
      models=args[:models].split(',').map(&:to_sym)
    end

    ElasticUtil.reindex(Collection, ElasticUtil::Index::COLLECTION) if models.include?(:collection)
    # Docsets are a special type of collection, intentionally using same index
    ElasticUtil.reindex(DocumentSet, ElasticUtil::Index::COLLECTION) if models.include?(:document_set)
    ElasticUtil.reindex(Page, ElasticUtil::Index::PAGE) if models.include?(:page)
    ElasticUtil.reindex(User.where.not(owner: 0, account_type: 'staff'),ElasticUtil::Index::USER) if models.include?(:user)
    ElasticUtil.reindex(Work.where.not(collection_id: 0), ElasticUtil::Index::WORK) if models.include?(:work)
  end

  desc "Reindex everything into elasticsearch"
  task :es_reindex, [:models] => :environment do |t,args|
    # look in the arguments for specific models to reindex
    # if none are provided, reindex everything
    if args[:models].blank?
      models=[:collection, :document_set, :page, :user, :work]
    else
      models=args[:models].split(',').map(&:to_sym)
    end

    ElasticUtil.reindex(Collection, ElasticUtil::Index::COLLECTION) if models.include?(:collection)
    # Docsets are a special type of collection, intentionally using same index
    ElasticUtil.reindex(DocumentSet, ElasticUtil::Index::COLLECTION) if models.include?(:document_set)
    ElasticUtil.reindex(Page, ElasticUtil::Index::PAGE) if models.include?(:page)
    ElasticUtil.reindex(User.where.not(owner: 0, account_type: 'staff'),ElasticUtil::Index::USER) if models.include?(:user)
    ElasticUtil.reindex(Work.where.not(collection_id: 0), ElasticUtil::Index::WORK) if models.include?(:work)
  end

  desc "Query ElasticSearch for a specific document by the ID which our application knows about"
  task :es_get, [:id] => :environment do |t,args|
    client = ElasticUtil.get_client()
    id = args[:id]

    # loop through all current elasticsearch indices to query for the document we want
    ElasticUtil::Index::ALL.each do |index|
      print "Checking index: #{index}\n"
      resp = client.get(index: index, id: id, ignore: [404])
      print JSON.pretty_generate(resp.to_json)
      print "\n\n"
    end
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
