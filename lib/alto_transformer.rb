module AltoTransformer
  
  def self.plaintext_from_alto_xml(alto_xml)
    # convert the alto XML string to plaintext using Nokogiri
    doc = Nokogiri::XML(alto_xml)
    # get the text blocks
    text_blocks = doc.search('TextBlock')
    # iterate through the text blocks
    paragraphs = []
    text_blocks.each do |text_block|
      # iterate through each text line
      lines = []
      text_block.search('TextLine').each do |text_line|
        # iterate through each string
        words = []
        text_line.search('String').each do |string|
          # get the content of the string
          string_content = string['CONTENT']
          # get the content of the string
          string_content = string_content.gsub(/[\n\r]/, ' ')
          # get the content of the string
          string_content = string_content.gsub(/\s+/, ' ')
          # get the content of the string
          string_content = string_content.strip
          # print the content of the string
          words << string_content
        end
        lines << words.join(' ')
      end
      paragraphs << lines.join("\n")
    end
    # return the text
    paragraphs.join("\n\n")
  end



  def self.alto_xml_from_quartex_xml(quartex_xml)
    # convert the Quartex XML string to ALTO XML using Nokogiri
    quartex_doc = Nokogiri::XML(quartex_xml)
    alto_doc= Nokogiri::XML(File.read(File.join(Rails.root, 'public', 'alto-sample.xml')))

    # quartex only has a root element page, then line elements and word elements
    # find the TextBlock element in the alto file so that we can replace its contents
    text_block = alto_doc.search('TextBlock').first
    # remove all child elements of the TextBlock element
    text_block.children.remove
    # iterate through quartex line elements and add them to the TextBlock element
    quartex_doc.search('line').each do |quartex_line|
      # convert the quartex line element to an ALTO line element
      alto_line = self.quartex_line_to_alto_line(quartex_line, alto_doc)
      # add the line to the TextBlock element
      text_block.add_child(alto_line)
    end
    # now convert the height and width attributes of the quartex page element to the alto page element
    # get the height and width of the quartex page element
    quartex_height = quartex_doc.at_xpath('//page')['height']
    quartex_width = quartex_doc.at_xpath('//page')['width']
    # get the alto page element
    alto_page = alto_doc.search('Page').first
    # set the height and width attributes of the alto page element
    alto_page['HEIGHT'] = quartex_height
    alto_page['WIDTH'] = quartex_width

    # now return the alto doc as a string
    alto_doc.to_xml    
  end 

  private


  def self.quartex_line_to_alto_line(quartex_element, alto_doc)
    # convert the Quartex line element to an ALTO line element
    alto_line = Nokogiri::XML::Node.new('TextLine', alto_doc)
    # quartex does not assign ID attributes to their nodes so we need to make one up
    # how many line elements already exist in the alto doc?
    alto_line['ID'] = "L#{alto_doc.search('TextLine').count + 1}"

    # add all words from the quartex element to the alto line
    quartex_element.search('word').each do |word|
      # convert the quartex word element to an ALTO word element
      alto_word = self.quartex_word_to_alto_word(word, alto_doc)
      # add the word to the line
      alto_line.add_child(alto_word)
    end
    # TODO calculate the bounding box of the line IF NEEDED
    
    alto_line
  end

  def self.quartex_word_to_alto_word(quartex_element, alto_doc)
    # convert the Quartex word element to an ALTO word element
    alto_word = Nokogiri::XML::Node.new('String', alto_doc)
    # quartex does not assign ID attributes to their nodes so we need to make one up
    # how many word elements already exist in the alto doc?
    alto_word['ID'] = "S#{alto_doc.search('String').count + 1}"
    # get the content of the word
    alto_word['CONTENT'] = quartex_element.text
    # convert quartex lrtb coordinates to alto lthw coordinates
    left= quartex_element['left']
    right= quartex_element['right']
    top= quartex_element['top']
    bottom= quartex_element['bottom']
    # get the width and height of the word
    width= right.to_i - left.to_i
    height= bottom.to_i - top.to_i
    alto_word['HPOS'] = left
    alto_word['VPOS'] = top
    alto_word['WIDTH'] = width
    alto_word['HEIGHT'] = height
    
    alto_word
  end
    


end