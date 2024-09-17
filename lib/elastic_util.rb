module ElasticUtil

  def self.get_client(enable_log = false)
    return Elasticsearch::Client.new(
      log: enable_log,
      cloud_id: ELASTIC_CLOUD_ID,
      api_key: ELASTIC_API_KEY
    )
  end

  def self.gen_bulk_action(index, body)
    bulk_action = {
      index: {
        _index: index,
        _id: body[:_id],
        data: body.except(:_id)
      }
    }

    return bulk_action
  end

  def self.reindex(model, index_name)
    client = self.get_client()

    model.find_in_batches(batch_size: 1000) do |batch|
      bulk_body = []
      batch.each do |item|
        bulk_body.push(
          ElasticUtil.gen_bulk_action(index_name, item.as_indexed_json())
        )
      end

      client.bulk(body: bulk_body, refresh: false)
    end

    client.indices.refresh(index: index_name)
  end

end
