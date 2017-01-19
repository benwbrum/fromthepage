module AbstractXmlController
#TODO rename this


  ##############################################
  # All code to manipulate source transcription
  # belongs here.
  ##############################################

  #constant - words to ignore when autolinking
  STOPWORDS = ["Mrs", "Mrs.", "Mr.", "Mr", "Dr.", "Dr"]

  def autolink(text)
    #find the list of articles
    sql = 'select distinct article_id, '+
          'display_text '+
          'from page_article_links ' +
          'inner join articles a '+
          'on a.id = article_id ' +
          "where a.collection_id = #{@collection.id}"
    logger.debug(sql)
    matches =
      Page.connection.select_all(sql).to_a
    # Bug 18 -- longest possible match is best
    matches.sort! { |x,y| x['display_text'].length <=> y['display_text'].length }
    matches.reverse!
    #for each article, check text to see if it needs to be linked
    for match in matches
      match_regex = Regexp.new('\b'+match['display_text'].gsub('?', '\?').gsub('.', '\.')+'\b', Regexp::IGNORECASE)
      display_text = match['display_text']
      logger.debug("DEBUG looking for #{match_regex}")
      if display_text.in?(STOPWORDS)
        #if the match is a stopword, ignore it and move to the next match
                
      else
        #match the regex, scanning each remaining portion of the text until you have no more matches
        matched_word = text.match match_regex
        remainder = text
        while matched_word != nil
          position = remainder.index match_regex
          #check to see if the regex is already within a link, from each index
          if word_not_okay(remainder, position, display_text) || within_link(remainder, position)
            #if it's in a link, don't do anything  
          else
            # not within a link, so create a new one
            article = Article.find(match['article_id'].to_i)
            # Bug 19 -- simplify when possible
            if article.title == display_text
            #  text.sub!(/\b(?<!\[\[)#{match_regex}(?!\]\]\b)/, "[[#{article.title}]]")
              text.sub!(match_regex, "[[#{article.title}]]")

            else
            #  text.sub!(/\b(?<!\[\[)#{match_regex}(?!\]\])\b/, "[[#{article.title}|#{display_text}]]")
              text.sub!(match_regex, "[[#{article.title}|#{display_text}]]")

            end
          end
          remainder = matched_word.post_match

          matched_word = remainder.match match_regex
        end
      end
    end
    return text
  end

  # check for word boundaries on preceding and following sides
  def word_not_okay(text, index, display_text)
    # test for characters before the display text
    if index > 1
      if text[(index-1),1].match /\w/
        return true
      end
    end
    # possibly do something for after the match.
    # reject word boundaries that aren't inflectional, plus special cases
    # i.e. (Mr shouldn't link Mrs)
    if index + display_text.size + 2 < text.size
      next_two = text[index + display_text.size, 2]
      unless next_two.match /\w/
        # we're not in a word boundary
        # check for inflectional endings that might pass
        unless (next_two.match(/.+s/) || next_two.match(/.+d/))
          return false
        end
      end
    end

    # consider rejecting some words
    return false
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
