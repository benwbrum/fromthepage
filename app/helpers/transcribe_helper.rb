module TranscribeHelper
  def excerpt_subject(page, title, options = {})
    options[:text_type] ||= 'transcription'
    options[:radius] ||= 3

    search_text = case options[:text_type]
                  when 'translation'
                    page.source_translation
                  when 'transcription'
                    page.source_text
                  else
                    "[[#{title}]]"
                  end
    subject_context(search_text, title, options[:radius])
  end

  private

  def subject_context(text, title, line_radius)
    line_radius = 0 if line_radius < 0 # Just in case
    line_radius += 1 # Makes the "radius" make more sense as a value

    output = "<b>#{title}</b>" # have something to return if the match fails
    regexed_title = /(\[\[#{title.gsub('(', '\(').gsub(')', '\)').gsub(/\s+/, '\s+')}.*?\]\])/m
    match = text.match(regexed_title)

    unless match.nil?

      pivot, end_index = match.offset(0)

      # Generate a list of \n indexes including 0 index and final index
      newlines = [0]
      text.to_enum(:scan, /\n/).each { |_m,| newlines.push $`.size }
      newlines.push(text.length)

      ## Sensible index defaults
      pre = 0
      post = text.length - 1

      # Separate the \n before and after the main match (ignore \n in the title)
      left, right = newlines.uniq
                            .reject { |idx| idx > pivot && idx < end_index }
                            .partition { |idx| idx < pivot }

      # Set new pre/post indexes based on line radius
      pre = left.last(line_radius).min + 1 unless left.empty?
      post = right.first(line_radius).max unless right.empty?

      output = text[pre..post].sub(regexed_title, '<b>\1</b>').strip

    end

    output
  end

  def osd_source(page, work)
    if page.nil?
      sources = []
      work.pages.each do |page|
        sources += osd_source(page, work)
      end
      sources
    else
      if page.sc_canvas
        ["#{page.sc_canvas.sc_service_id}/info.json"]
      elsif page.ia_leaf
        [page.ia_leaf.iiif_image_info_url]
      elsif browser.platform.ios? && browser.webkit?
        ["#{url_for(:root)}image-service/#{page.id}/info.json"]
      else
        [{type: 'image', url: file_to_url(page.canonical_facsimile_url)}.to_json]
      end
    end
  end
end
