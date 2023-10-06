module DescriptionTagger
  def self.tag_description_by_subject(description, tags, title="")
    client = OpenAI::Client.new
    response = client.completions(
      parameters: {
        model: "gpt-3.5-turbo-instruct",
        prompt: prompt_by_subject(description, tags, title),
        max_tokens: 100,
        n: 1,
        temperature: 0.7,
        top_p: 1.0,
        frequency_penalty: 0.0,
        presence_penalty: 0.0
      }
    )
    raw_text = response['choices'].first['text']
    print raw_text
    response_tags = raw_text.split(', ').map{|e| e.strip}
  end

  def tag_description_by_date(description, tags, title)
  end


  def self.prompt_by_subject(description, tags, title)
    @@subject_prompt ||= File.read(File.join(Rails.root, 'lib', 'openai', 'subject_prompt.txt'))

    prompt = @@subject_prompt.gsub("{{tags}}", tags.to_json) 
    unless title.blank?
      description = title + "\n" + description
    end
    prompt.gsub!("{{description}}", description)

    prompt
  end

  def prompt_by_date(description, tags, title)
    @@date_prompt ||= File.read(File.join(Rails.root, 'lib', 'openai', 'date_prompt.txt'))
  end

end