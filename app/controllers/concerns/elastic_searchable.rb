module ElasticSearchable
  require 'elastic_util'
  extend ActiveSupport::Concern

  def elastic_search_results(query, page, page_size, filter, query_config)
    return nil if query.nil?

    search_types = ['collection', 'page', 'user', 'work']
    # Narrow down types based on query_config
    if query_config.present?
      case query_config[:type]
      when "org"
        search_types = ['collection', 'page', 'work']
      when "collection", "docset"
        search_types = ['page', 'work']
      when "work"
        search_types = ['page']
      end
    end

    if filter
      count_query = ElasticUtil.gen_query(
        user: current_user,
        query: query,
        types: search_types,
        query_config: query_config,
        page: page,
        page_size: page_size,
        count_only: true
      )

      # Need to run a count query for all types
      # TODO: Could use msearch for one call to ES
      resp = ElasticUtil.safe_search(
        index: count_query[:indexes],
        body: count_query[:query_body]
      )

      # No real inflation happens here but we get counts back
      inflated_resp = ElasticUtil.inflate_response(resp)

      full_count = inflated_resp[:full_count]
      type_counts = inflated_resp[:type_counts]

      filtered_query = ElasticUtil.gen_query(
        user: current_user,
        query: query,
        types: [filter],
        query_config: query_config,
        page: page,
        page_size: page_size
      )

      filtered_resp = ElasticUtil.safe_search(
        index: filtered_query[:indexes],
        body: filtered_query[:query_body]
      )

      # Actual object inflation for the filtered set
      inflated_resp = ElasticUtil.inflate_response(filtered_resp)

      # Blend all/filtered for display
      return {
        inflated: inflated_resp[:inflated],
        full_count: full_count,
        filtered_count: inflated_resp[:filtered_count],
        type_counts: type_counts
      }
    else
      generated_query = ElasticUtil.gen_query(
        user: current_user,
        query: query,
        types: ['collection', 'page', 'user', 'work'],
        query_config: query_config,
        page: page,
        page_size: page_size
      )

      resp = ElasticUtil.safe_search(
        index: generated_query[:indexes],
        body: generated_query[:query_body]
      )

      return ElasticUtil.inflate_response(resp)
    end
  end
end
