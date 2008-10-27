module PrintHelper
  MINIMUM_TITLE_TO_EXPAND = 8
  TITLE_TO_TEXT_THRESHOLD = 4
  
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
      if print_footnote?(id, title, latex_link) 
        latex_link += "\\footnote{#{title}}"
      end
      link.replace_with(REXML::Text.new(latex_link))
    end
    
    page.elements.each("//p") do |para|
      latex << "\n\n" 
      para.each do |e|
        #p e
        latex << e.to_s
      end
    end
    # clear the footnote array in case render is called twice for debugging
    return latex
    
  end
  
  
  private
  def print_footnote?(id, title, text)
    @printed_before ||= {}
    # have we printed the footnote before?
    logger.debug "DEBUG: @printed_before[#{id}] == #{@printed_before[id].to_s} (#{title})"
    if @printed_before[id] == true
      logger.debug "DEBUG: bailing because we've printed this link before"
      return false
    end
    logger.debug "DEBUG: exited bailout"
    # is it long enough to expand?
    logger.debug "DEBUG: is #{title.length} > #{MINIMUM_TITLE_TO_EXPAND} ? "
    if title.length > MINIMUM_TITLE_TO_EXPAND
      if title.length - text.length > TITLE_TO_TEXT_THRESHOLD
        logger.debug "DEBUG: printing the link"
        @printed_before[id] = true
        logger.debug "DEBG: set @printed_before[#{id}] = true (#{@printed_before[id]})"
        return true
      end
    end
    # does it have article text
    false
  end
end
