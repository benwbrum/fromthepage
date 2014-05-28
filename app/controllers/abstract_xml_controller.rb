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
      match_regex = Regexp.new('\b'+match['display_text'].gsub('?', '\?')+'\b')
      display_text = match['display_text']
      logger.debug("DEBUG looking for #{match_regex}")
      if text.match match_regex
        logger.debug("DEBUG found #{match_regex}")
        # is this already within a link?

        match_start = text.index match_regex
        if word_not_okay(text, match_start, display_text)||within_link(text, match_start)
          # within a link, but try again somehow
        else
          # not within a link, so create a new one
          logger.debug("DEBUG #{match_regex} is not a link 2")
          article = Article.find(match['article_id'].to_i)
          # Bug 19 -- simplify when possible
          if article.title == display_text
            text.sub!(match_regex, "[[#{article.title}]]")
          else
            text.sub!(match_regex, "[[#{article.title}|#{display_text}]]")
          end
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
        unless (next_two.match(/.+s/) || next_two.match(/.+d/) || display_text != 'Mr')
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
