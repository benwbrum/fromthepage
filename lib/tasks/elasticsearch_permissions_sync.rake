require 'json'
require 'elastic_util'

namespace :fromthepage do
  STATE_PATH = 'index-state.json'

  desc "Sync permissions changes to the index"
  task :es_sync, [] => :environment do |t,args|
    after = get_last_index_time()
    snapshot = Time.now.utc.to_i

    persist_state(after, 'INDEXING')

    begin
      # Permissions updates
      sync_collections_and_docsets(after, snapshot);
      sync_works(after, snapshot);

      # Page content updates
      sync_pages(after, snapshot);

      persist_state(snapshot, 'IDLE')
    rescue Exception
      # log the exception
      pp $!
      # Keep same time, change state to ERROR so it'll try again
      persist_state(after, 'ERROR')
    end
  end

  def get_last_index_time
    if File.exist?(STATE_PATH)
      data = File.read(STATE_PATH)
      state = JSON.parse(data)

      # Abandon ship if previous indexing underway
      if state['status'] == 'INDEXING'
        exit
      end

      return state['last_updated']
    else
      return Time.now.utc.to_i
    end
  end

  def persist_state(timestamp, status)
    body = {
      last_updated: timestamp,
      status: status
    }

    pretty = JSON.pretty_generate(body)

    File.open(STATE_PATH, 'w') do |file|
      file.write(pretty)
    end
  end

  def gen_range_query(after, limit)
    q = {
      query: {
        range: {
          permissions_updated: {
            gte: after,
            lt: limit
          }
        }
      },
      # There is possibility of leakage if a document is updated during
      # this process.  That can cause page offsets to behave wonky as the result
      # sets shift.  Could solve with a PIT if activity levels exceed 10000 permission
      # events per update
      size: 10000
    }
  end

  def sync_collections_and_docsets(after, limit)
    q = gen_range_query(after, limit)

    resp = ElasticUtil.safe_search(index: ElasticUtil::Index::COLLECTION, body: q)

    collection_ids = resp['hits']['hits']
      .select { |x| !x['_source']['is_docset'] } 
      .map { |x| x['_id'] }

    docset_ids = resp['hits']['hits']
      .select { |x| x['_source']['is_docset'] } 
      .map { |x| x['_id'][7..-1] } # Have to drop prefix

    collection_ids.each do |coll_id|
      c = Collection.find(coll_id)
      ElasticUtil.reindex(c.pages, ElasticUtil::Index::PAGE)
      ElasticUtil.reindex(c.works, ElasticUtil::Index::WORK)
    end

    docset_ids.each do |docset_id|
      ds = DocumentSet.find(docset_id)
      ElasticUtil.reindex(ds.pages, ElasticUtil::Index::PAGE)
      ElasticUtil.reindex(ds.works, ElasticUtil::Index::WORK)
    end
  end

  def sync_works(after, limit)
    q = gen_range_query(after, limit)

    resp = ElasticUtil.safe_search(index: ElasticUtil::Index::WORK, body: q)
    work_ids = resp['hits']['hits']
      .map { |x| x['_id'] }

    work_ids.each do |work_id|
      w = Work.find(work_id)
      ElasticUtil.reindex(w.pages, ElasticUtil::Index::PAGE)
    end
  end

  def sync_pages(after, limit)
    terminus_a_quo = DateTime.strptime(after.to_s,'%s')
    terminus_ad_quem = DateTime.strptime(limit.to_s,'%s')
    pending = Page.where(updated_at: [terminus_a_quo..terminus_ad_quem])

    ElasticUtil.reindex(pending, ElasticUtil::Index::PAGE)
  end
end
