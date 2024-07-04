module DiffTools

  def self.diff_and_replace(text_a, text_b, replacement)
    # this method compares two strings and produces a third string which contains all identical text, with the differences replaced by the replacement string
    # compare the two strings
    diff = Diffy::Diff.new(text_a, text_b, include_diff_info: true)
    # diffly has code which marks up the differences within a line in HTML, using strong tags to identify words
    # we want to replace the words which are different with the replacement string
    # it's easiest to convert the diffly output to HTML, then use Nokogiri to parse the HTML and replace the words
    # convert the diffly output to HTML
    diff_html = diff.to_s(:html)
    # parse the HTML
    doc = Nokogiri::HTML(diff_html)
    # iterate through the strong tags
    doc.search('strong').each do |strong|
      # replace the content of the strong tag with the replacement string
      strong.content = replacement
    end
    # now we want to take the HTML and convert it back to plaintext
    lines = []
    # iterate through the li tags
    doc.search('li').each do |li|
      # if the li tag has a class of del, ignore it
      next if ['del', 'diff-comment', 'diff-block-info'].include? li['class']

      # add the plaintext content of the li tag to the lines array
      lines << li.content
    end
    # return the lines array joined by newlines
    lines.join("\n")
  end

  def self.replace_words(_text, replacement)
    # find all the words in the text which contain the replacement string, and substitute them with the replacement string
    diff.gsub(/\b\w+#{replacement}\w+\b/m, replacement)
  end

end
