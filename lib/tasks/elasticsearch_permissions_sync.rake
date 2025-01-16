require 'json'
require 'elastic_util'

namespace :fromthepage do
  desc "Sync permissions changes to the index"
  task :es_sync, [] => :environment do |t,args|
    after = 0
    snapshot = Time.now.utc.to_i

    sync_collections_and_docsets(after, snapshot);
    sync_works(after, snapshot);
  end

  def gen_range_query(after, limit)
    q = {
      query: {
        range: {
          permissions_updated: {
            gte: after,
            #lt: limit # May bring this back if I do paging 
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
