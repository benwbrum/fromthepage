module SubjectCoocurrenceExporter
  class Exporter

    include Rails.application.routes.url_helpers

    def initialize(collection, article = nil)
      @collection = collection
      @article = article
      @subjects = collection.articles.includes(:categories, :page_article_links).order('articles.title')
      @headers = [
        'Subject Title',
        'Subject ID',
        'Subject URI',
        'Subject Latitude',
        'Subject Longitude',
        'Subject Categories',
        'Coocurrence Title',
        'Coocurrence ID',
        'Coocurrence URI',
        'Coocurrence Latitude',
        'Coocurrence Longitude',
        'Shared Page Count'
      ]
    end

    def export
      # sql =
      #   'SELECT count(*) as link_count, '+
      #   'a.title as title, '+
      #   'a.id as article_id '+
      #   'FROM page_article_links to_links '+
      #   'INNER JOIN page_article_links from_links '+
      #   '  ON to_links.page_id = from_links.page_id '+
      #   'INNER JOIN articles a '+
      #   '  ON from_links.article_id = a.id '+
      #   "WHERE to_links.article_id = #{@article.id} "+
      #   " AND from_links.article_id != #{@article.id} "
      # sql += "GROUP BY a.title, a.id "

      sql =
        'SELECT count(*) as link_count, ' \
        'from_a.title as from_title, ' \
        'from_a.id as from_article_id, ' \
        'from_a.uri as from_article_uri, ' \
        'from_a.latitude as from_article_longitude, ' \
        'from_a.longitude as from_article_latitude, ' \
        'to_a.title as to_title, ' \
        'to_a.id as to_article_id, ' \
        'to_a.uri as to_article_uri, ' \
        'to_a.latitude as to_article_longitude, ' \
        'to_a.longitude as to_article_latitude ' \
        'FROM page_article_links to_links ' \
        'INNER JOIN page_article_links from_links   ' \
        'ON to_links.page_id = from_links.page_id ' \
        'INNER JOIN articles from_a   ' \
        'ON from_links.article_id = from_a.id ' \
        'INNER JOIN articles to_a   ' \
        'ON to_links.article_id = to_a.id ' \
        'WHERE to_links.article_id != from_links.article_id   ' \
        "AND to_a.collection_id = #{@collection.id} "
      sql += 'GROUP BY from_a.title, from_a.id '
      article_links = Article.connection.select_all(sql)

      sql = "SELECT articles_categories.article_id as article_id,
              categories.title as title
              FROM articles_categories
              INNER JOIN articles
                ON articles_categories.article_id = articles.id
              INNER JOIN categories
                ON articles_categories.category_id = categories.id
              WHERE articles.collection_id = #{@collection.id}"
      categories = Article.connection.select_all(sql)
      category_map = {}
      categories.each do |element|
        category_map[element['article_id']] ||= []
        category_map[element['article_id']] << element['title']
      end

      CSV.generate(force_quotes: true) do |csv|
        csv << @headers
        current_category_stragg = nil
        article_links.each do |coocurrence|
          current_categories = category_map[coocurrence['from_article_id']]
          if current_categories
            current_category_stragg = current_categories.uniq.join(' | ')
          else
            current_category_stragg = ''
          end
          csv << [
            coocurrence['from_title'],
            coocurrence['from_article_id'],
            coocurrence['from_article_uri'],
            coocurrence['from_article_longitude'],
            coocurrence['from_article_latitude'],
            current_category_stragg,
            coocurrence['to_title'],
            coocurrence['to_article_id'],
            coocurrence['to_article_uri'],
            coocurrence['to_article_longitude'],
            coocurrence['to_article_latitude'],
            coocurrence['link_count']
          ]
        end
      end

      # csv_string = CSV.generate(force_quotes: true) do |csv|
      #   csv << @headers

      #   @subjects.each do |subject|
      #     row = []
      #     row << subject.title
      #     row << subject.uri
      #     row << subject.categories.map { |category| category.title }.join("; ")
      #     row << Rails.application.routes.url_helpers.collection_article_show_url(@collection.owner, @collection, subject.id)
      #     row << subject.source_text.split(/\s/).count
      #     row << subject.source_text.chars.count
      #     row << subject.page_article_links.count
      #     row << if subject.provenance.blank? then 'FromThePage' else subject.provenance end
      #     row << subject.created_on.iso8601

      #     csv << row
      #   end
      # end
      # csv_string
    end

  end
end
