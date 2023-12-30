module TextNormalizer
  def self.normalize_text(raw_text)
    client = OpenAI::Client.new
    prompt = normalize_prompt(raw_text)
    response = client.chat(
      parameters: {
        model: "gpt-3.5-turbo-16k",
        messages: [
          {role: "system", content: "You are a scholarly editor who is preparing historical documents for publication."},
          {role: "user", content: prompt}
        ],
        max_tokens: 16000,
        n: 1,
        temperature: 0.0,
        top_p: 1.0,
        frequency_penalty: 0.0,
        presence_penalty: 0.0
      }
    )
    print prompt
    print "\n"
    if response['choices'].nil? || response['choices'].empty? || response['choices'].first['message'].nil?
      pp response
      return []
    end

    text = response['choices'].first['message']['content']


    print text
    print "\n\n\n"
    text.sub(/\ATEXT\s/m, '')
  end




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

  def self.normalize_prompt(raw_text)
    @@normalize_prompt ||= File.read(File.join(Rails.root, 'lib', 'openai', 'normalizer_prompt.txt'))

    prompt = @@normalize_prompt.gsub("{{text}}", raw_text) 

    prompt
  end

end