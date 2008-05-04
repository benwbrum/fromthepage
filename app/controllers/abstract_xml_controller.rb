module AbstractXmlController 
#TODO rename this


  ##############################################
  # All code to manipulate source transcription
  # belongs here. 
  ##############################################

  def autolink(text)
    sql = 'select distinct article_id, '+
          'display_text '+
          'from page_article_links ' +
          'inner join articles a '+
          'on a.id = article_id ' +
          "where a.collection_id = #{@collection.id}" 
    logger.debug(sql)
    matches = 
      Page.connection.select_all(sql)

    # Bug 18 -- longest possible match is best
    matches.sort! { |x,y| x['display_text'].length <=> y['display_text'].length }
    matches.reverse!

    for match in matches
      display_text = match['display_text']
      logger.debug("DEBUG looking for #{display_text}")
      if text.include? display_text
        logger.debug("DEBUG found #{display_text}")
        # is this already within a link?
        
        match_start = text.index display_text
        if within_link(text, match_start)
          # within a link, but try again somehow
        else
          # not within a link, so create a new one
          logger.debug("DEBUG #{display_text} is not a link 2")
          article = Article.find(match['article_id'].to_i)
          # Bug 19 -- simplify when possible
          if article.title == display_text
            text.sub!(display_text, "[[#{article.title}]]")
          else
            text.sub!(display_text, "[[#{article.title}|#{display_text}]]")
          end
        end 
      end
    end  
    return text
  end 

  def within_link(text, index)
    if open_link = text.rindex('[[', index)
      # a begin-link precedes this
      if close_link = text.rindex(']]', index)
        # a close-link precedes this
        if open_link < close_link
          # close link was more recent than open, so we're not inside
          # a link already
          false
        else
          # we're inside a link
          true
        end
      else
        # no close-link precedes this, but a begin-link does
        # therefore we're inside a link: do nothing
        true
      end
    else
      # no open_link precedes this
      false
    end   
  end
end
