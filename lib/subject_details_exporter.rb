module SubjectDetailsExporter
  class Exporter
    include Rails.application.routes.url_helpers

    def initialize(collection)
      @collection=collection
      @subjects = collection.articles.includes(:categories, :page_article_links).order('articles.title')
      @headers = [
        'Title',
        'External URI',
        'Categories',
        'Subject URI',
        'Disambiguator',
        'Latitude',
        'Longitude',
        'Birth Date',
        'Death Date',
        'Race Description',
        'Sex',
        'Bibliography',
        'Article Length (Words)',
        'Article Length (Characters)',
        'Article Text',
        'Number Occurrences',
        'Origin',
        'Created',
        'Category_Hierarchy'
      ]  # research helpers may follow
    end

    def export
      csv_string = CSV.generate(force_quotes: true) do |csv|
        csv << @headers

        @subjects.each do |subject|
          row = []
          row << subject.title
          row << subject.uri
          row << subject.categories.map { |category| category.title }.join('; ')
          row << Rails.application.routes.url_helpers.collection_article_show_url(@collection.owner, @collection, subject.id)
          row << subject.short_summary
          row << subject.latitude
          row << subject.longitude
          row << subject.birth_date
          row << subject.death_date
          row << subject.race_description
          row << subject.sex
          row << subject.bibliography
          row << subject.source_text.split(/\s/).count
          row << subject.source_text.chars.count
          row << subject.source_text
          row << subject.page_article_links.count
          row << if subject.provenance.blank? then 'FromThePage' else subject.provenance end
          row << subject.created_on.iso8601
          row << subject.formatted_category_hierarchy

          csv << row
        end
      end

      csv_string
    end
  end
end
