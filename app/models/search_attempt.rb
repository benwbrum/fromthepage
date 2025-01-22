# == Schema Information
#
# Table name: search_attempts
#
#  id              :integer          not null, primary key
#  clicks          :integer          default(0)
#  contributions   :integer          default(0)
#  hits            :integer          default(0)
#  owner           :boolean          default(FALSE)
#  query           :string(255)
#  search_type     :string(255)
#  slug            :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  collection_id   :integer
#  document_set_id :bigint
#  user_id         :integer
#  visit_id        :integer
#  work_id         :integer
#
# Indexes
#
#  index_search_attempts_on_collection_id    (collection_id)
#  index_search_attempts_on_document_set_id  (document_set_id)
#  index_search_attempts_on_slug             (slug) UNIQUE
#  index_search_attempts_on_user_id          (user_id)
#  index_search_attempts_on_visit_id         (visit_id)
#  index_search_attempts_on_work_id          (work_id)
#
class SearchAttempt < ApplicationRecord
    require 'elastic_util'

    belongs_to :user, optional: true
    belongs_to :collection, optional: true
    belongs_to :work, optional: true
    belongs_to :document_set, optional: true
    visitable class_name: "Visit" # ahoy integration

    after_create :update_slug

    def to_param
        "#{query.parameterize}-#{id}"
    end

    def update_slug
        update_attribute(:slug, to_param)
    end

    def results_link
        paths = Rails.application.routes.url_helpers
        case search_type
        when "work"
            paths.paged_search_path(self)
        when "collection"
            paths.paged_search_path(self)
        when "collection-title"
            if collection.present?
                paths.collection_path(collection.owner, collection, search_attempt_id: id)
            else # document_set
                paths.collection_path(document_set.owner, document_set, search_attempt_id: id)
            end
        when "findaproject"
            paths.search_attempt_show_path(self)
        end
    end

    def results(page = 1, page_size = 30)
        query = sanitize_and_format_search_string(self.query)

        case search_type
        when "work"
            if work.present? && query.present?
                if ELASTIC_ENABLED
                    query = prep_sqs_operators(query)
                    results = elastic_work_search(work, query, page, page_size)
                else
                    query = precise_search_string(query)
                    results = database_work_search(work, query)
                end
            else
                results = Page.none
            end

        when "collection"
            collection_or_document_set = collection || document_set
            if collection_or_document_set.present? && query.present?
                if ELASTIC_ENABLED
                  query = prep_sqs_operators(query)
                  results = elastic_collection_search(collection_or_document_set, query, page, page_size)
                else
                  query = precise_search_string(query)
                  results = database_collection_search(collection_or_document_set, query)
                end
            else 
                results = Page.none
            end
        
        when "collection-title"
            collection_or_document_set = collection || document_set
            results = collection_or_document_set.search_works(query).includes(:work_statistic)

        when "findaproject"
            results = Collection.search(query).unrestricted + DocumentSet.search(query).unrestricted
        end

        update_attribute(:hits, results&.count || 0)
        return results
    end

    private
    # when "collection" search handlers
    def database_collection_search(coll_or_docset, query)
        return Page.order('work_id, position')
                    .joins(:work)
                    .where(work_id: coll_or_docset.works.ids)
                    .where("MATCH(search_text) AGAINST(? IN BOOLEAN MODE)", query)
    end

    def elastic_collection_search(coll_or_docset, query, page, page_size)
        # Assuming access-control is handled earlier
        # Filter on collection only here, works join against DB happens later
        filter = {}
        if coll_or_docset.is_a?(Collection)
          filter = {term: {collection_id: coll_or_docset.id}}
        elsif coll_or_docset.is_a?(DocumentSet)
          filter = {term: {docset_id: coll_or_docset.id}}
        end

        # Generate query and setup filter/paging in wrapper
        query_body = Page.es_match_query(query, nil)
        query_body[:bool][:filter] = filter # Replace filter
        query_wrapper = {
          query: query_body,
          from: (page[:page].to_i - 1) * page_size,
          size: page_size
        }

        # Issue query
        resp = ElasticUtil.safe_search(index: 'ftp_page', body: query_wrapper)
        matches = resp['hits']['hits'].map { |doc| doc['_id'] }
        results = Page.order('work_id', 'position')
                    .joins(:work)
                    .where(work_id: coll_or_docset.works.ids)
                    .where(id: matches)

        # Apply ES relevance
        results = results.sort_by { |x| matches.index(x[:id].to_s) }

        return WillPaginate::Collection.create(page[:page].to_i, 30, resp['hits']['total']['value']) do |pager|
          pager.replace(results)
        end
    end

    # when "work" search handlers
    def database_work_search(work, query)
      return Page.order('work_id, position')
                  .joins(:work)
                  .where(work_id: work.id)
                  .where("MATCH(search_text) AGAINST(? IN BOOLEAN MODE)", query)
    end

    def elastic_work_search(work, query, page, page_size)
      filter = [
        {term: {is_public: true} },
        {term: {work_id: work.id} }
      ]

      # Generate query and setup filter/paging in wrapper
      query_body = Page.es_match_query(query, nil)
      query_body[:bool][:filter] = filter # Replace filter
      query_wrapper = {
        query: query_body,
        from: (page[:page].to_i - 1) * page_size,
        size: page_size
      }

      # Send query
      resp = ElasticUtil.safe_search(index: 'ftp_page', body: query_wrapper)
      matches = resp['hits']['hits'].map { |doc| doc['_id'] }
      results = Page.order('work_id', 'position')
                  .joins(:work)
                  .where(work_id: work.id)
                  .where(id: matches)

      # Apply ES relevance
      results = results.sort_by { |x| matches.index(x[:id].to_s) }

      return WillPaginate::Collection.create(page[:page].to_i, 30, resp['hits']['total']['value']) do |pager|
        pager.replace(results)
      end
    end

    def sanitize_and_format_search_string(search_string)
        return '' unless search_string.present?
        string = CGI::escapeHTML(search_string)
    end

    def precise_search_string(search_string)
        # convert 'natural' search strings unless they're precise
        return search_string if search_string.match(/["+-]/)

        search_string.gsub!(/\s+/, ' ')
        "+\"#{search_string}\""
    end

    # Simple Query String does not support AND/OR/NOT out of the box but instead
    # uses symbols to replace them.  This method converts string representations
    # to the SQS symbols
    def prep_sqs_operators(search_string)
      search_string.gsub!("&quot;", "\"") # Not sure where &quot; comes from
      search_string.gsub!("AND ", " +")
      search_string.gsub!("NOT ", " -")
      search_string.gsub!("OR ", " | ")
      search_string
    end
end
