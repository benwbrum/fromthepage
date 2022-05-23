module SubjectDistributionExporter
  class Exporter
    include Rails.application.routes.url_helpers

    def initialize(collection, article)
      @collection=collection
      @article=article
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
        'Work Identifier',
        'Work URI'
      ] # plus work metadata
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




      # we actually want to find all the works this subject is mentioned in,
      # then get all the pages in those works and all the subjects in those pages.
      work_ids = @article.pages.pluck(:work_id)
      work_ids = work_ids & @collection.works.pluck("works.id")
      page_in_works_ids = Page.where(work_id: work_ids).pluck(:id)


      sql = 
        'select count(*) as link_count, '+
        '  works.id as work_id, '+
        'works.original_metadata as work_original_metadata, '+
        'works.title as work_title, '+
        'works.identifier as work_identifier, '+
        '  to_a.id, '+
        'to_a.title as to_title, '+
        'to_a.id as to_article_id, '+
        'to_a.uri as to_article_uri, '+
        'to_a.latitude as to_article_longitude, '+
        'to_a.longitude as to_article_latitude '+
        'from page_article_links to_links '+
        'INNER JOIN articles to_a '+
        '  ON to_links.article_id = to_a.id '+
        'inner join pages p '+
        'on to_links.page_id = p.id '+
        'inner join works '+
        'on works.id = p.work_id '+
        "WHERE to_links.article_id != #{@article.id} " +
        "  AND to_links.page_id IN (#{page_in_works_ids.join(',')}) " +
        'group by works.id, to_a.id'


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
        category_map[element["article_id"]] ||= []
        category_map[element["article_id"]] << element["title"]
      end

      csv_string = CSV.generate(force_quotes: true) do |csv|
        csv << @headers
        current_category_stragg = nil
        article_links.each do |coocurrence|
          current_categories = category_map[coocurrence['to_article_id']]
          if current_categories
            current_category_stragg = current_categories.uniq.join (" | ")
          else
            current_category_stragg = ''
          end

          csv << [
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
        end
      end
      csv_string

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
