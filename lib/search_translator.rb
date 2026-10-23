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
    all_titles=all_links.map { |e| e['target_title'] }
    uniq_titles=all_titles.uniq

    all_abbrevs=[]
    doc.xpath('//expan').each { |e| all_abbrevs << e['orig'] unless e['orig'].blank? }
    doc.xpath('//abbr').each { |e| all_abbrevs << e.text }
    uniq_titles += all_abbrevs.uniq

    newline_separated_titles=uniq_titles.join("\n")

    newline_separated_titles
  end

  def self.search_translation_from_xml(xml_translation)
    strip_markup(xml_translation)
  end

private
  def self.strip_markup(xml_text)
    doc = Nokogiri::XML(xml_text)
    doc.search('lb').each do |lb|
      if lb['break'] && lb['break'] == 'no'
        # do nothing -- this had a hyphen
      else
        lb.add_child(' ')
      end
    end
    doc.xpath('//p').each { |n| n.add_next_sibling("\n") }
    doc.xpath('//br').each { |n| n.replace("\n") }
    doc.xpath('//div').each { |n| n.add_next_sibling("\n") }
    doc.xpath('//abbr').each { |n| n.replace(n['expan']) unless n['expan'].blank? }
    doc.xpath('//catchword').each { |n| n.remove }

    table_text="\n\n"
    doc.xpath('//tr').each do |row|
      row.xpath('td').each do |cell|
        table_text << cell.text
        table_text << ' '
      end
      table_text << "\n"
    end

    doc.xpath('//table').each { |n| n.replace(table_text) }


    no_tags = doc.text
    no_linefeeds = no_tags.gsub(/\s/, ' ')
    single_spaces = no_linefeeds.gsub(/ +/, ' ').strip

    single_spaces
  end
end
