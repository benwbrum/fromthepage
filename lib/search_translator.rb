module SearchTranslator
  
  def self.search_text_from_xml(xml_transcript, xml_translation)
    search_verbatim_from_xml(xml_transcript)     +
    "\n\n" +
    search_canonical_from_xml(xml_transcript)    +
    "\n\n" +
    search_translation_from_xml(xml_translation)    
  end

  def self.search_verbatim_from_xml(xml_transcript)
    strip_markup(xml_transcript)
   end
  
  def self.search_canonical_from_xml(xml_transcript)
    doc = Nokogiri::XML(xml_transcript)

    all_links=doc.search('link')
    all_titles=all_links.map{ |e| e['target_title'] }
    uniq_titles=all_titles.uniq
    newline_separated_titles=uniq_titles.join("\n")

    newline_separated_titles
  end
  
  def self.search_translation_from_xml(xml_translation)
    strip_markup(xml_translation)
  end

private
  def self.strip_markup(xml_text)
    doc = Nokogiri::XML(xml_text)
    
    no_tags = doc.text
    no_linefeeds = no_tags.gsub(/\s/, ' ')
    single_spaces = no_linefeeds.gsub(/\s{2,}/, ' ')

    single_spaces    
  end

end