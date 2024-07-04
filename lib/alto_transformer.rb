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

end
