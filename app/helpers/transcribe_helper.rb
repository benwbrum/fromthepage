module TranscribeHelper

  def subject_context(text, title, line_radius=3)
    line_radius = 1 if line_radius < 2 # Just in case
    output = "" # have something to return if the match fails
    
    regexed_title = /(\[\[#{title.gsub(/\s*/, '\s*')}.*?\]\])/m
    match = text.match(regexed_title)

    unless match == nil

      pivot, end_index = match.offset(0)

      # Generate a list of \n indexes
      linebreaks = [0]
      text.to_enum(:scan,/\n/).each {|m,| linebreaks.push $`.size}

      ## Sensible index defaults
      pre = 0
      post = text.length - 1

      # Separate the \n before and after the main match (ignore \n in the title)
      left, right = linebreaks.reject{|idx| idx > pivot && idx < end_index }
        .partition {|idx| idx < pivot }

      # Set new pre/post indexes based on line radius
      pre = left.last(line_radius).min unless left.empty?
      post = right.first(line_radius).max unless right.empty?

      output = text[pre..post].sub(regexed_title, '<b>\1</b>')

    end

    return output
  end
end
