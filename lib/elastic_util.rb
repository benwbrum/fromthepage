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

end
