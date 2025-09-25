class SearchAttempt::Lib::Utils
  def self.highlight_terms(transcription, search_string)
    doc = Nokogiri::HTML.fragment(transcription)
    words_regex = /\b(#{search_string.split(' ').join('|')})\b/i

    doc.traverse do |node|
      if node.text? && node.parent.name != 'script'
        node.replace(
          node.text.gsub(words_regex) do |match|
            "<span class=\"highlighted\">#{match}</span>"
          end
        )
      end
    end

    doc.to_html.html_safe
  end

  def self.generate_link(search_attempt)
    url_helpers = Rails.application.routes.url_helpers
    case search_attempt.search_type
    when 'work'
      url_helpers.paged_search_path(search_attempt, format: :html)
    when 'collection'
      url_helpers.paged_search_path(search_attempt, format: :html)
    when 'collection-title'
      collection = search_attempt.collection || search_attempt.document_set
      url_helpers.collection_path(collection.owner, collection, search_attempt_id: search_attempt.id, format: :html)
    when 'findaproject'
      url_helpers.search_attempt_path(search_attempt, format: :html)
    end
  end

  def self.query_results(search_attempt)
    query = sanitize_and_format_search_string(search_attempt.query)

    case search_attempt.search_type
    when 'work'
      if search_attempt.work_id.present? && query.present?
        query = precise_search_string(query)
        results = Page.order('work_id, position')
                      .joins(:work)
                      .where(work_id: search_attempt.work_id)
                      .where('MATCH(search_text) AGAINST(? IN BOOLEAN MODE)', query)
      else
        results = Page.none
      end
    when 'collection'
      collection = search_attempt.collection || search_attempt.document_set

      if collection.present? && query.present?
        query = precise_search_string(query)
        results = Page.order('work_id, position')
                      .joins(:work)
                      .where(work_id: collection.works.select(:id))
                      .where('MATCH(search_text) AGAINST(? IN BOOLEAN MODE)', query)
      else
        results = Page.none
      end
    when 'collection-title'
      collection = search_attempt.collection || search_attempt.document_set
      results = collection.search_works(query).includes(:work_statistic)
    else
      # when 'findaproject'
      results = Collection.search(query).unrestricted + DocumentSet.search(query).unrestricted
    end

    search_attempt.update_attribute(:hits, results.count)

    results
  end

  def self.sanitize_and_format_search_string(search_string)
    return '' unless search_string.present?

    CGI.escapeHTML(search_string)
  end

  def self.precise_search_string(search_string)
    return search_string if search_string.match(/["+-]/)

    search_string.gsub!(/\s+/, ' ')
    "+\"#{search_string}\""
  end
end
