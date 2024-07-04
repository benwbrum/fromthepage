module SubjectDetailsExporter
  class Exporter

    include Rails.application.routes.url_helpers

    def initialize(collection)
      @collection = collection
      @subjects = collection.articles.includes(:categories, :page_article_links).order('articles.title')
      @headers = [
        'Title',
        'External URI',
        'Categories',
        'Subject URI',
        'Latitude',
        'Longitude',
        'Article Length (Words)',
        'Article Length (Characters)',
        'Article Text',
        'Number Occurrences',
        'Origin',
        'Created',
        'Category_Hierarchy'
      ] # research helpers may follow
    end

    def export
      CSV.generate(force_quotes: true) do |csv|
        csv << @headers

        @subjects.each do |subject|
          row = []
          row << subject.title
          row << subject.uri
          row << subject.categories.map(&:title).join('; ')
          row << Rails.application.routes.url_helpers.collection_article_show_url(@collection.owner, @collection, subject.id)
          row << subject.latitude
          row << subject.longitude
          row << subject.source_text.split(/\s/).count
          row << subject.source_text.chars.count
          row << subject.source_text
          row << subject.page_article_links.count
          row << (subject.provenance.presence || 'FromThePage')
          row << subject.created_on.iso8601
          row << subject.formatted_category_hierarchy

          csv << row
        end
      end
    end

  end
end
