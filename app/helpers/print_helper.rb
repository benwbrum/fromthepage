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
#      if print_footnote?(id, title, latex_link)
#        latex_link += "\\footnote{#{title}}"
#      end
      latex_link += make_footnote_if_necessary(id, title, latex_link)
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
  def make_footnote_if_necessary(id, title, text)
    @printed_before ||= {}
    # have we printed the footnote before?
    logger.debug "DEBUG: @printed_before[#{id}] == #{@printed_before[id].to_s} (#{title})"
    if @printed_before[id] == true
      logger.debug "DEBUG: bailing because we've printed this link before"
      return ""
    end
    logger.debug "DEBUG: exited bailout"
    # does it have an article with text?
    begin
      article = Article.find(id)
      unless article.source_text.blank?
        article_text = article_to_latex(article.xml_text)
        logger.debug "DEBUG: converted xml to latex:\#{article.xml_text}\n#{article_text}"
        return "\\footnote{#{title}\n \n \n\n\n#{article_text}}"
      end
    rescue ActiveRecord::RecordNotFound
      logger.error("ERROR: could not find article by id #{id} linked from [[#{title}|#{text}]]")
    end
    # is it long enough to expand?
    logger.debug "DEBUG: is #{title.length} > #{MINIMUM_TITLE_TO_EXPAND} ? "
    if title.length > MINIMUM_TITLE_TO_EXPAND
      if title.length - text.length > TITLE_TO_TEXT_THRESHOLD
        logger.debug "DEBUG: printing the link"
        @printed_before[id] = true
        logger.debug "DEBG: set @printed_before[#{id}] = true (#{@printed_before[id]})"
        return "\\footnote{#{title}}"
      end
    end
    ""
  end

  def article_to_latex(article)
    latex = ""
    internal = REXML::Document.new(article.gsub(/\n/, ''))
    article = internal.elements.to_a("//page").first

    # first do some scrubbing
    article.elements.each("//lb") do |lb|
      lb.replace_with(REXML::Text.new("\n"))
    end

    article.elements.each("//link") do |link|
      latex_link = link.children.to_s
      link.replace_with(REXML::Text.new(latex_link))
    end

    article.elements.each("//p") do |para|
      latex << "\n \n \n"
      para.each do |e|
        #p e
        latex << e.to_s
      end
    end
    # clear the footnote array in case render is called twice for debugging
    return latex
  end
end
