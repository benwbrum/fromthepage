require 'nokogiri'

module SubjectExporter
  class Exporter
    def initialize(collection)
      @works = collection.works
      @headers = %w[Work_Title Identifier Section Section_Subjects Page_Title Page_Position Page_URL Subject Text External_URI Category Subject_URI]
    end

    def export
      csv_string = CSV.generate(force_quotes: true) do |csv|
        csv << @headers
        @works.each do |work|
          transcription_sections  = ['']
          translation_sections    = ['']

          work.pages.each do |page|
            sections_by_link, transcription_sections, section_to_subjects = links_by_section(page.xml_text, {}, transcription_sections)
            sections_by_link, translation_sections, section_to_subjects = links_by_section(page.xml_translation, sections_by_link, translation_sections, section_to_subjects)

            page_url = "http://#{Rails.application.routes.default_url_options[:host]}/display/display_page?page_id=#{page.id}"
            page.page_article_links.each do |link|
              display_text = link.display_text.gsub('<lb/>', ' ').delete("\n")
              article = link.article
              categories = []

              article.categories.each { |category| categories << category.title }
              article_link = Rails.application.routes.url_helpers.collection_article_show_path(article.collection.owner, article.collection, article.id, :only_path => false)

              categories.sort!
              section_header = sections_by_link[link.id] 
              csv << [
                work.title,
                work.identifier,
                section_header,
                section_to_subjects[section_header],
                page.title,
                page.position,
                page_url,
                article.title,
                display_text,
                article.uri,
                categories.first(3).join('|'),
                article_link
              ]
            end
          end
        end
      end
      csv_string
    end

    def links_by_section(xml, links_hash, section_array, section_to_subjects={})
      page = Nokogiri::XML(xml)

      page.search('*').each do |e|
        case e.name
        when 'link'
          _, *sections = section_array
          links_hash[e['link_id'].to_i] = sections.join('|')
        when 'entryHeading'

          pop_depth = e['depth'].to_i - section_array.length

          section_title = e['title']
          link_for_section = ""
          links = e.xpath('link')
          if links.count > 0
            section_to_subjects[section_title] = links.map{|link| link['target_title']}.join('||') 
          end
          
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

      [links_hash, section_array, section_to_subjects]
    end
  end
end
