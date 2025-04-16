class Xml::Lib::Utils
  STRIKETHROUGH_TAGS = ['s', 'del']
  UNDERLINE_TAGS = ['ins', 'u']
  SOUL_RISKY_TAGS = STRIKETHROUGH_TAGS + UNDERLINE_TAGS

  # TODO: extend functionality for other problematic nested tags
  def self.handle_soul_risky_tags(doc)
    risky_tag_replacements = {}

    SOUL_RISKY_TAGS.each do |risky_tag|
      doc.each_element("//#{risky_tag}") do |risky_element|
        next if SOUL_RISKY_TAGS.include?(risky_element.parent.name)

        key = SecureRandom.uuid
        risky_tag_replacement = handle_soul_risky_element(risky_element)
        risky_tag_replacements[key] = risky_tag_replacement

        risky_element.parent.insert_before(risky_element, REXML::Text.new("REPLACEMERISKYTAGS#{key}"))
        risky_element.remove
      end
    end

    risky_tag_replacements
  end

  def self.handle_soul_risky_element(risky_element)
    output_segments = []

    risky_element.children.each do |child|
      output_segments << if child.is_a?(REXML::Element) && SOUL_RISKY_TAGS.include?(child.name)
                           handle_soul_risky_element(child)
                         else
                           child.to_s.strip
                         end
    end

    # Extend this for different tags with special handling
    if STRIKETHROUGH_TAGS.include?(risky_element.name)
      if UNDERLINE_TAGS.include?(risky_element.parent.name)
        "]{.ul}[#{output_segments.join}]{.ulst}["
      else
        "~~#{output_segments.join}~~"
      end
    elsif UNDERLINE_TAGS.include?(risky_element.name)
      if STRIKETHROUGH_TAGS.include?(risky_element.parent.name)
        "~~[#{output_segments.join}]{.ulst}~~"
      else
        "[#{output_segments.join}]{.ul}"
      end
    end
  end

  private

  def risky_root_tag?(risky_element)
    return if SOUL_RISKY_TAGS.include?(risky_element.parent.name)
  end
end
