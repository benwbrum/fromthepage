require 'nokogiri'

module SubjectExporter
  class Exporter
    include Rails.application.routes.url_helpers

    def initialize(collection, works)
      @works = works ? works : collection.works
      @headers = %w[Work_Title Identifier Section Section_Subjects Page_Title Page_Position Page_URL Subject Text Text_Type External_URI Category Subject_URI Subject_Latitude Subject_Longitude Subject_Description Category_Hierarchy]
      @metadata_keys = collection.metadata_coverages.map{|c| c.key}
    end

    def export
      csv_string = CSV.generate(force_quotes: true) do |csv|
        csv << @headers + @metadata_keys

        ac_map = {}
        collection = @works.first.collection
        owner = collection.owner
        collection.articles.includes(:categories).each do |article|
          ac_map[article] = article.categories.map{|c| c.title}.sort
        end

        @works.each do |work|
          GC.start
          transcription_sections  = ['']
          translation_sections    = ['']

          metadata_row = []
          unless work.original_metadata.blank?
            metadata = {}
            JSON.parse(work.original_metadata).each {|e| metadata[e['label']] = e['value'] }

            @metadata_keys.each do |header|
              # look up the value for this index
              metadata_row << metadata[header]
            end
          end

          work.pages.includes(:page_article_links, articles: [:page_article_links]).each do |page|
            sections_by_link, transcription_sections, section_to_subjects = links_by_section(page.xml_text, {}, transcription_sections)
            sections_by_link, translation_sections, section_to_subjects = links_by_section(page.xml_translation, sections_by_link, translation_sections, section_to_subjects)

            page_url = url_for(:controller => 'display', :action => 'display_page', :page_id => page.id, :only_path => false)
            # page.page_article_links.includes(:article).each do |link|
            page.page_article_links.each do |link|
              display_text = link.display_text.gsub('<lb/>', ' ').delete("\n")
              article = link.article
              if article.nil?
                Rails.logger.warn("WARNING: Export could not find article for link #{link.display_text} on page #{page.title}")
              else
                categories = ac_map[article] || []
                article_link = Rails.application.routes.url_helpers.collection_article_show_url(owner, collection, article.id, :only_path => false)
                section_header = sections_by_link[link.id] 
                row = [
                  work.title,
                  work.identifier,
                  section_header,
                  section_to_subjects[section_header],
                  page.title,
                  page.position,
                  page_url,
                  article.title,
                  display_text,
                  link.text_type,
                  article.uri,
                  categories.first(3).join('|'),
                  article_link,
                  article.latitude,
                  article.longitude,
                  article.source_text,
                  article.formatted_category_hierarchy
                ]
                csv << row + metadata_row
              end
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
