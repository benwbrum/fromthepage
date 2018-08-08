module TranscribeHelper

  def subject_context(text, title, line_radius=3)
    line_radius = 0 if line_radius < 0 # Just in case
    line_radius += 1 # Makes the "radius" make more sense as a value

    output = "<b>#{title}</b>" # have something to return if the match fails
    
    regexed_title = /(\[\[#{title.gsub(/\s*/, '\s*')}.*?\]\])/m
    match = text.match(regexed_title)

    unless match == nil

      pivot, end_index = match.offset(0)

      # Generate a list of \n indexes including 0 index and final index
      linebreaks = [0]
      text.to_enum(:scan,/\n/).each {|m,| linebreaks.push $`.size}
      linebreaks.push(text.length)
      
      ## Sensible index defaults
      pre = 0
      post = text.length - 1

      # Separate the \n before and after the main match (ignore \n in the title)
      left, right = linebreaks.uniq.reject{|idx| idx > pivot && idx < end_index }
        .partition {|idx| idx < pivot }

      # Set new pre/post indexes based on line radius
      pre = left.last(line_radius).min + 1 unless left.empty?
      post = right.first(line_radius).max unless right.empty?

      output = text[pre..post].sub(regexed_title, '<b>\1</b>').strip()

    end

    return output
  end
end
