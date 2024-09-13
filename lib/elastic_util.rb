module ElasticUtil

  def self.get_client(enable_log = false)
    return Elasticsearch::Client.new(
      log: enable_log,
      cloud_id: ELASTIC_CLOUD_ID,
      api_key: ELASTIC_API_KEY
    )
  end

end
