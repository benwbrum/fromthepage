require 'nokogiri'

module SubjectExporter

  class Exporter
    def initialize(collection)
      @works = collection.works
      @headers = %w[Work_Title Identifier Section Page_Title Page_Position Page_URL Subject Text Category Category Category]
    end

    def export
      csv_string = CSV.generate(force_quotes: true) do |csv|
        csv << @headers
        @works.each do |work|
          section_array = ['']
          work.pages.each do |page|
            sections_by_link = {}
            sections_by_link, section_depth = links_by_section(page.xml_text, sections_by_link, section_array)
            page_url = "http://#{Rails.application.routes.default_url_options[:host]}/display/display_page?page_id=#{page.id}"
            page.page_article_links.each do |link|
              display_text = link.display_text.gsub('<lb/>', ' ').delete("\n")
              article = link.article
              categories = []

              article.categories.each { |category| categories << category.title }

              categories.sort!

              csv << [
                work.title,
                work.identifier,
                sections_by_link[link.id],
                page.title,
                page.position,
                page_url,
                link.article.title,
                display_text,
                categories.first(3).join('|')
              ]
            end
          end
        end
      end
      csv_string
    end

    def links_by_section(xml, links_hash, section_array)
      page = Nokogiri::XML(xml)

      page.search('*').each do |e|
        case e.name
        when 'link'
          _, *sections = section_array
          links_hash[e['link_id'].to_i] = sections.join('|')
        when 'entryHeading'

          pop_depth = e['depth'].to_i - section_array.length

          section_title = e['title']

          if pop_depth > 0
            section_array << section_title
          elsif pop_depth == 0
            section_array.pop
            section_array << section_title
          elsif pop_depth < 0
            section_array.pop(pop_depth.abs)
            section_array.pop
            section_array << section_title
          end
        end
      end

      [links_hash, section_array]
    end
  end
end