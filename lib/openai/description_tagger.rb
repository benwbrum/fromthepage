module DescriptionTagger
  def self.tag_description_by_subject(description, tags, title = '')
    client = OpenAI::Client.new
    prompt = prompt_by_subject(description, tags, title)
    response = client.chat(
      parameters: {
        model: 'gpt-3.5-turbo-16k',
        messages: [
          { role: 'system', content: 'You are a metadata librarian with experience classifying documents by subject.' },
          { role: 'user', content: prompt }
        ],
        max_tokens: 100,
        n: 1,
        temperature: 0.0,
        top_p: 1.0,
        frequency_penalty: 0.0,
        presence_penalty: 0.0
      }
    )
    print prompt
    print "\n"
    if response['choices'].nil?
      pp response
      return []
    end

    raw_text = response['choices'].first['message']['content']

    response_tags = []
    print raw_text
    print "\n\n\n"
    unless raw_text.match(/NOT ENOUGH INFORMATION/)
      begin
        response_tags = JSON.parse(raw_text)
        if response_tags.is_a? String
          response_tags = response_tags.split(',').map { |e| e.gsub('[', '').gsub(']', '').gsub('"', '').gsub(/\b'/, '').gsub(/'\b/, '').strip }
        end

      rescue JSON::ParserError => e
        print "WARNING: response could not be parsed as JSON\nRESPONSE: #{raw_text}\n"
        raw_text.gsub!('POSSIBLE_TAGS:', '')
        raw_text.gsub!('RESPONSE:', '')
        raw_text.gsub!('Tags:', '')
        response_tags = raw_text.split(',').map { |e| e.gsub('[', '').gsub(']', '').gsub('"', '').gsub(/\b'/, '').gsub(/'\b/, '').strip }
      end
    end
    pp response_tags
    response_tags
  end

  def tag_description_by_date(description, tags, title)
  end


  def self.prompt_by_subject(description, tags, title)
    @@subject_prompt ||= File.read(File.join(Rails.root, 'lib', 'openai', 'subject_prompt.txt'))

    prompt = @@subject_prompt.gsub('{{tags}}', tags.to_json)
    unless title.blank?
      description = title + "\n" + description
    end
    prompt.gsub!('{{description}}', description)

    prompt
  end

  def prompt_by_date(description, tags, title)
    @@date_prompt ||= File.read(File.join(Rails.root, 'lib', 'openai', 'date_prompt.txt'))
  end
end
