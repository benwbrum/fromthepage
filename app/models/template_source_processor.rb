module TemplateSourceProcessor
  
  def generate_template
    @fragment = Nokogiri::HTML.fragment(self.source_text)
    
    nodes = @fragment.search('./span[starts-with(@class, "contribution-mark-")]')
    nodes.each do |markElement|
      markElement.content = "{{ #{toKey(markElement.attributes['class'].value)} }}"
    end
    self.source_template = @fragment.to_html
  end
  
  private
  def toKey(value)
    value = value.split(' ')[0];
    return value.gsub('-','_').camelize(:lower)
  end 
end
