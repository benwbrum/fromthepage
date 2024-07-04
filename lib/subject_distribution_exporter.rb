module SubjectDistributionExporter
  class Exporter

    include Rails.application.routes.url_helpers

    def initialize(collection, article)
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
        'Coocurrence Count',
        'Work Title',
        'Work FromThePage ID',
        'Work Identifier'
      ] # plus work metadata

      raw_metadata_strings = collection.works.pluck(:original_metadata)
      @metadata_headers = raw_metadata_strings.map { |raw| raw.nil? ? [] : JSON.parse(raw).pluck('label') }.flatten.uniq
    end

    def export
      # we actually want to find all the works this subject is mentioned in,
      # then get all the pages in those works and all the subjects in those pages.
      work_ids = @article.pages.pluck(:work_id)
      work_ids &= @collection.works.pluck('works.id')
      page_in_works_ids = Page.where(work_id: work_ids).pluck(:id)

      if page_in_works_ids.empty?
        article_links = []
      else

        sql =
          'select count(*) as link_count,   ' \
          'works.id as work_id, ' \
          'works.original_metadata as work_original_metadata, ' \
          'works.title as work_title, ' \
          'works.identifier as work_identifier,   ' \
          'to_a.id, ' \
          'to_a.title as to_title, ' \
          'to_a.id as to_article_id, ' \
          'to_a.uri as to_article_uri, ' \
          'to_a.latitude as to_article_longitude, ' \
          'to_a.longitude as to_article_latitude ' \
          'from page_article_links to_links ' \
          'INNER JOIN articles to_a   ' \
          'ON to_links.article_id = to_a.id ' \
          'inner join pages p ' \
          'on to_links.page_id = p.id ' \
          'inner join works ' \
          'on works.id = p.work_id ' \
          "WHERE to_links.article_id != #{@article.id}   " \
          "AND to_links.page_id IN (#{page_in_works_ids.join(',')}) " \
          'group by works.id, to_a.id'

        article_links = Article.connection.select_all(sql)
      end

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
        csv << (@headers + @metadata_headers)
        current_category_stragg = nil
        article_links.each do |coocurrence|
          current_categories = category_map[coocurrence['to_article_id']]
          if current_categories
            current_category_stragg = current_categories.uniq.join(' | ')
          else
            current_category_stragg = ''
          end

          row = [
            coocurrence['to_title'],
            coocurrence['to_article_id'],
            coocurrence['to_article_uri'],
            coocurrence['to_article_longitude'],
            coocurrence['to_article_latitude'],
            current_category_stragg,
            coocurrence['link_count'],
            coocurrence['work_title'],
            coocurrence['work_id'],
            coocurrence['work_identifier']
          ]
          if coocurrence['work_original_metadata'].present?
            metadata = {}
            JSON.parse(coocurrence['work_original_metadata']).each { |e| metadata[e['label']] = e['value'] }

            @metadata_headers.each do |header|
              # look up the value for this index
              row << metadata[header]
            end
          end

          csv << row
        end
      end
    end

  end
end
