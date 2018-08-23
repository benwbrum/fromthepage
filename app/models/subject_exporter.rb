class SubjectExporter
  def initialize(collection)
    @collection = collection
    @works = collection.works
    @headers = %w[Work_Title Identifier Page_Title Page_Position Page_URL Subject Text Category Category Category]
  end

  def export
    csv_string = CSV.generate(force_quotes: true) do |csv|
      csv << @headers
      @collection.works.each do |work|
        work.pages.each do |page|
          page_url = "http://#{Rails.application.routes.default_url_options[:host]}/display/display_page?page_id=#{page.id}"
          page.page_article_links.each do |link|
            display_text = link.display_text.gsub('<lb/>', ' ').delete("\n")
            article = link.article
            category_array = []

            article.categories.each { |category| category_array << category.title }

            category_array.sort!

            csv << [
              work.title,
              work.identifier,
              page.title,
              page.position,
              page_url,
              link.article.title,
              display_text,
              category_array.first(3).join('|')
            ]
          end
        end
      end
    end
    csv_string
  end
end
