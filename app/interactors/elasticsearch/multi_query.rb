class Elasticsearch::MultiQuery < ApplicationInteractor
  attr_accessor :results, :collections, :document_sets, :works, :pages, :users,
                :total_count, :type_counts, :org_filter, :collection_filter, :docset_filter,
                :work_filter, :response

  DEFAULT_PAGE_SIZE = 10
  MAX_SEARCH_RESULTS = 10_000

  def initialize(query:, query_params:, page: 1, scope: nil, user: nil)
    @query = query
    @query_params = query_params
    @page = page.to_i
    @scope = scope
    @user = user

    @collections   = []
    @document_sets = []
    @works         = []
    @pages         = []
    @users         = []
    @results       = []
    @total_count   = 0
    @type_counts   = {}

    @org_filter = nil

    super
  end

  def perform
    @indexes = build_base_query

    @response = Chewy.client.search(
      index: @indexes,
      body: base_query
    )

    Rails.logger.info("[Elasticsearch] Indexes: #{@indexes.inspect}")
    Rails.logger.info("[Elasticsearch] Query Body: #{base_query.to_json}")
    Rails.logger.info("[Elasticsearch] Raw Response: #{@response.inspect}")

    inflate_results

    @results = WillPaginate::Collection.create(@page, DEFAULT_PAGE_SIZE,
                                               [ MAX_SEARCH_RESULTS, filtered_count ].min) do |pager|
      pager.replace(@results)
    end
  end

  private

  def augmented_query
    return @augmented_query if defined?(@augmented_query)

    if @query.nil? || @query.include?('"')
      @augmented_query = @query

      return @augmented_query
    end

    tokens = @query.split

    augmented_tokens = tokens.map do |t|
      if t.nil? || t.include?('"') || !t.match?(/[.\-_]/)
        t
      else
        '"' + t + '"'
      end
    end

    @augmented_query = augmented_tokens.join(' ')

    @augmented_query
  end

  def base_query
    @base_query ||= {
      query: {
        bool:  {
          must: {
            bool: {
              should: []
            }
          },
          filter: []
        }
      },
      aggs: {
        type_counts: {
          terms: {
            field: '_index',
            size: DEFAULT_PAGE_SIZE
          }
        },
        total_doc_count: {
          sum_bucket: {
            buckets_path: 'type_counts>_count'
          }
        }
      },
      indices_boost: [
        { UsersIndex.index_name => 1000.0 },
        { CollectionsIndex.index_name => 50.0 },
        { WorksIndex.index_name => 10.0 },
        { PagesIndex.index_name => 1.0 }
      ],
      from: (@page - 1) * DEFAULT_PAGE_SIZE,
      size: DEFAULT_PAGE_SIZE
    }
  end

  def build_base_query
    case @scope
    when 'collection'
      base_query[:post_filter] = {
        prefix: {
          _index: CollectionsIndex.index_name
        }
      }
    when 'work'
      base_query[:post_filter] = {
        prefix: {
          _index: WorksIndex.index_name
        }
      }
    when 'page'
      base_query[:post_filter] = {
        prefix: {
          _index: PagesIndex.index_name
        }
      }
    end

    if @query_params[:org].present?
      @org_filter = User.find_by(slug: @query_params[:org])
      owner_user_id = @org_filter&.id

      if owner_user_id.present?
        base_query[:query][:bool][:filter] << { term: { owner_user_id: owner_user_id } }

        base_query[:query][:bool][:must][:bool][:should] << collection_query
        base_query[:query][:bool][:must][:bool][:should] << document_set_query
        base_query[:query][:bool][:must][:bool][:should] << page_query
        base_query[:query][:bool][:must][:bool][:should] << work_query

        return [ CollectionsIndex.index_name, PagesIndex.index_name, WorksIndex.index_name ]
      end
    end

    if @query_params[:mode] == 'collection' && @query_params[:slug].present?
      @collection_filter = Collection.find_by(slug: @query_params[:slug])
      collection_id = @collection_filter&.id

      if collection_id.present?
        base_query[:query][:bool][:filter] << { term: { collection_id: collection_id } }

        base_query[:query][:bool][:must][:bool][:should] << page_query
        base_query[:query][:bool][:must][:bool][:should] << work_query

        return [ PagesIndex.index_name, WorksIndex.index_name ]
      end
    end

    if @query_params[:mode] == 'docset' && @query_params[:slug].present?
      @docset_filter = DocumentSet.find_by(slug: @query_params[:slug])
      docset_id = @docset_filter&.id

      if docset_id.present?
        base_query[:query][:bool][:filter] << { term: { docset_id: docset_id } }

        base_query[:query][:bool][:must][:bool][:should] << page_query
        base_query[:query][:bool][:must][:bool][:should] << work_query

        return [ PagesIndex.index_name, WorksIndex.index_name ]
      end
    end

    if @query_params[:mode] == 'work' && @query_params[:slug].present?
      @work_filter = Work.find_by(slug: @query_params[:slug])
      work_id = @work_filter&.id

      if work_id.present?
        base_query[:query][:bool][:filter] << { term: { work_id: work_id } }

        base_query[:query][:bool][:must][:bool][:should] << page_query

        return [ PagesIndex.index_name ]
      end
    end

    base_query[:query][:bool][:must][:bool][:should] << collection_query
    base_query[:query][:bool][:must][:bool][:should] << document_set_query
    base_query[:query][:bool][:must][:bool][:should] << user_query
    base_query[:query][:bool][:must][:bool][:should] << page_query
    base_query[:query][:bool][:must][:bool][:should] << work_query

    [ CollectionsIndex.index_name, PagesIndex.index_name, UsersIndex.index_name, WorksIndex.index_name ]
  end

  def collection_query
    return @collection_query if defined?(@collection_query)

    query = Collection.es_search(query: augmented_query, user: @user)

    @collection_query = rendered_query(query)
  end

  def document_set_query
    return @document_set_query if defined?(@document_set_query)

    query = DocumentSet.es_search(query: augmented_query, user: @user)

    @document_set_query = rendered_query(query)
  end

  def user_query
    return @user_query if defined?(@user_query)

    query = User.es_search(query: augmented_query)

    @user_query = rendered_query(query)
  end

  def page_query
    return @page_query if defined?(@page_query)

    query = Page.es_search(query: augmented_query, user: @user)

    @page_query = rendered_query(query)
  end

  def work_query
    return @work_query if defined?(@work_query)

    query = Work.es_search(query: augmented_query, user: @user)

    @work_query = rendered_query(query)
  end

  def rendered_query(query)
    rendered_query = query.render[:body][:query]
    rendered_query[:bool][:filter] << { prefix: { _index: query.render[:index].first } }

    rendered_query
  end

  def inflate_results
    collection_ids = []
    docset_ids     = []
    page_ids       = []
    user_ids       = []
    work_ids       = []

    hits = @response['hits']['hits']
    doc_types = @response['aggregations']['type_counts']['buckets']
    @total_count = @response['aggregations']['total_doc_count']['value']

    hits.each do |hit|
      if hit['_index'] == CollectionsIndex.index_name && !hit['_source']['is_docset']
        collection_ids << hit['_id'].to_i
      elsif hit['_index'] == DocumentSetsIndex.index_name
        docset_ids << hit['_id'].gsub('docset-', '').to_i
      elsif hit['_index'] == PagesIndex.index_name
        page_ids << hit['_id'].to_i
      elsif hit['_index'] == UsersIndex.index_name
        user_ids << hit['_id'].to_i
      elsif hit['_index'] == WorksIndex.index_name
        work_ids << hit['_id'].to_i
      end
    end

    collections_map = Collection.includes(:owner).where(id: collection_ids).index_by(&:id)
    docsets_map = DocumentSet.includes(collection: :owner).where(id: docset_ids).index_by(&:id)
    pages_map = Page.includes(work: [ { collection: :owner }, :document_sets ]).where(id: page_ids).index_by(&:id)
    users_map = User.where(id: user_ids).index_by(&:id)
    works_map = Work.includes(collection: :owner).where(id: work_ids).index_by(&:id)

    hits.each do |hit|
      if hit['_index'] == CollectionsIndex.index_name && !hit['_source']['is_docset']
        hit_id = hit['_id'].to_i
        item = collections_map[hit_id]

        if item.present?
          @collections << item
          @results << item
        end
      elsif hit['_index'] == DocumentSetsIndex.index_name
        hit_id = hit['_id'].gsub('docset-', '').to_i
        item = docsets_map[hit_id]

        if item.present?
          @document_sets << item
          @results << item
        end
      elsif hit['_index'] == PagesIndex.index_name
        hit_id = hit['_id'].to_i
        item = pages_map[hit_id]

        if item.present?
          @pages << item
          @results << item
        end
      elsif hit['_index'] == UsersIndex.index_name
        hit_id = hit['_id'].to_i
        item = users_map[hit_id]

        if item.present?
          @users << item
          @results << item
        end
      elsif hit['_index'] == WorksIndex.index_name
        hit_id = hit['_id'].to_i
        item = works_map[hit_id]

        if item.present?
          @works << item
          @results << item
        end
      end
    end

    doc_types.each do |bucket|
      @type_counts[bucket['key'].to_sym] = bucket['doc_count'].to_i
    end
  end

  def filtered_count
    case @scope
    when 'collection'
      @type_counts[CollectionsIndex.index_name.to_sym]
    when 'work'
      @type_counts[WorksIndex.index_name.to_sym]
    when 'page'
      @type_counts[PagesIndex.index_name.to_sym]
    when 'user'
      @type_counts[UsersIndex.index_name.to_sym]
    else
      @total_count
    end
  end
end
