module TextNormalizer
  def self.normalize_text(raw_text)
    client = OpenAI::Client.new
    prompt = normalize_prompt(raw_text)
    response = client.chat(
      parameters: {
        model: 'gpt-3.5-turbo-16k',
        messages: [
          { role: 'system', content: 'You are a scholarly editor who is preparing historical documents for publication.' },
          { role: 'user', content: prompt }
        ],
        max_tokens: 10000,
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
      print "\nERROR  Response from OpenAI was not actionable:\n"
      pp response
      return []
    end

    text = response['choices'].first['message']['content']


    print text
    print "\n\n\n"
    text.sub(/\ATEXT\s/m, '')
  end



private

  def self.normalize_prompt(raw_text)
    @@normalize_prompt ||= File.read(File.join(Rails.root, 'lib', 'openai', 'normalizer_prompt.txt'))

    prompt = @@normalize_prompt.gsub('{{text}}', raw_text)

    prompt
  end
end
