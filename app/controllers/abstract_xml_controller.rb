module AbstractXmlController

  # TODO: rename this

  ##############################################
  # All code to manipulate source transcription
  # belongs here.
  ##############################################

  # constant - words to ignore when autolinking
  STOPWORDS = [
    'Mrs',
    'Mrs.',
    'Mr.',
    'Mr',
    'Dr.',
    'Dr',
    'Miss',
    'he',
    'she',
    'it',
    'wife',
    'husband',
    'I',
    'him',
    'her',
    'son',
    'daughter'
  ]
  STOPREGEX = /^\w\.?\$/

  def autolink(text)
    # find the list of articles
    if @collection.is_a?(DocumentSet)
      id = @collection.collection.id
    else
      id = @collection.id
    end

    sql = 'select article_id, ' \
          'display_text, ' \
          'max(page_article_links.created_on) last_reference ' \
          'from page_article_links ' \
          'inner join articles a ' \
          'on a.id = article_id ' \
          "where a.collection_id = #{id} " \
          'group by article_id, display_text ' \
          'union ' \
          'select id article_id, ' \
          'title display_text, ' \
          'created_on last_reference ' \
          'from articles ' \
          "where collection_id = #{id}"

    matches = Page.connection.select_all(sql).to_a
    matches.sort! { |x, y| [y['display_text'].length, y['last_reference']] <=> [x['display_text'].length, x['last_reference']] }
    # for each article, check text to see if it needs to be linked
    matches.each do |match|
      match_regex = Regexp.new("\\b#{Regexp.escape(match['display_text'])}\\b", Regexp::IGNORECASE)
      display_text = match['display_text']
      logger.debug("DEBUG looking for #{match_regex}")

      # if the match is a stopword, ignore it and move to the next match
      if display_text.in?(STOPWORDS) || display_text.match(STOPREGEX)
        # skip this one
      else
        # find the matches and substitute in as long as the text isn't already in a link
        text.gsub! match_regex do |m|
          # find the index of the match to check if it's with a larger link
          position = Regexp.last_match.offset(0)[0]
          # check to see if the regex is already within a link, from each index
          if word_not_okay(text, position, m) || within_link(text, position)
            m

          else
            # not within a link, so create a new one
            article = Article.find(match['article_id'].to_i)

            # check if regex match is exact (including case)
            if m == display_text
              # Bug 19 -- simplify when possible
              # if yes, use display text
              if article.title == display_text
                "[[#{article.title}]]"
              else
                "[[#{article.title}|#{display_text}]]"
              end
              # if not, use regex match
            else
              "[[#{article.title}|#{m}]]"
            end

          end
        end
      end
    end

    text
  end

  # check for word boundaries on preceding and following sides
  def word_not_okay(text, index, display_text)
    # test for characters before the display text
    return true if index > 1 && text[(index - 1), 1].match(/\w/)

    # possibly do something for after the match.
    # reject word boundaries that aren't inflectional, plus special cases
    # i.e. (Mr shouldn't link Mrs)
    if index + display_text.size + 2 < text.size
      next_two = text[index + display_text.size, 2]
      if !next_two.match(/\w/) && !(next_two.match(/.+s/) || next_two.match(/.+d/))
        # we're not in a word boundary
        # check for inflectional endings that might pass
        return false
      end
    end

    # consider rejecting some words
    false
  end

  def within_link(text, index)
    if (open_link = text.rindex('[[', index))
      # a begin-link precedes this
      if (close_link = text.rindex(']]', index))
        # a close-link precedes this
        open_link >= close_link
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
