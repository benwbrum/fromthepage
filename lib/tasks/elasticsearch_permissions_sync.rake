require 'json'
require 'elastic_util'

namespace :fromthepage do
  STATE_PATH = 'index-state.json'

  desc "Sync permissions changes to the index"
  task :es_sync, [] => :environment do |t,args|
    after = get_last_index_time()
    snapshot = Time.now.utc.to_i

    persist_state(after, 'INDEXING')
    sync_collections_and_docsets(after, snapshot);
    sync_works(after, snapshot);
    persist_state(snapshot, 'IDLE')
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

  def reindex_pages(lookup)
    lookup.find_in_batches(batch_size: 100) do |batch|
      bulk_body = []
      batch.each do |item|
        item_body = item.as_indexed_json()

        # Skip errors
        if item_body.key?(:indexing_error)
          next
        end

        bulk_body.push(
          ElasticUtil.gen_bulk_action('ftp_page', item_body)
        )
      end

      ElasticUtil.get_client().bulk(body: bulk_body, refresh: false)
    end
  end

  def sync_collections_and_docsets(after, limit)
    q = gen_range_query(after, limit)

    resp = ElasticUtil.safe_search(index: 'ftp_collection', body: q)

    collection_ids = resp['hits']['hits']
      .select { |x| !x['_source']['is_docset'] } 
      .map { |x| x['_id'] }

    docset_ids = resp['hits']['hits']
      .select { |x| x['_source']['is_docset'] } 
      .map { |x| x['_id'][7..-1] } # Have to drop prefix

    collection_ids.each do |coll_id|
      c = Collection.find(coll_id)
      reindex_pages(c.pages)
    end

    docset_ids.each do |docset_id|
      ds = DocumentSet.find(docset_id)
      reindex_pages(ds.pages)
    end
  end

  def sync_works(after, limit)
    q = gen_range_query(after, limit)

    resp = ElasticUtil.safe_search(index: 'ftp_work', body: q)
    work_ids = resp['hits']['hits']
      .map { |x| x['_id'] }

    work_ids.each do |work_id|
      w = Work.find(work_id)
      reindex_pages(w.pages)
    end
  end
end
