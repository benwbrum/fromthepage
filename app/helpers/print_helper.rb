module PrintHelper
  
  
  def xml_to_latex(page)
    latex = ""
    internal = REXML::Document.new(page.gsub(/\n/, ''))
    page = internal.elements.to_a("//page").first
    
    # first do some scrubbing
    page.elements.each("//lb") do |lb|
      lb.replace_with(REXML::Text.new("\n"))
    end
    
    page.elements.each("//link") do |link|
      title = link.attributes['target_title']
      id = link.attributes['target_id']
      latex_link = link.children.to_s
      link.replace_with(REXML::Text.new(latex_link))
    end
    
    page.elements.each("//p") do |para|
      latex << '\n\n' 
      para.each do |e|
        p e
        latex << e.to_s
      end
    end
    return latex
    
  end
  
  
  private
end
