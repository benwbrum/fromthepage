class Xml::Lib::Utils
  STRIKETHROUGH_TAGS = ['s', 'del'].freeze
  UNDERLINE_TAGS = ['ins', 'u'].freeze

  SOUL_RISKY_TAGS = STRIKETHROUGH_TAGS + UNDERLINE_TAGS

  # TODO: extend functionality for other problematic nested tags
  def self.handle_soul_risky_tags(doc)
    risky_tag_replacements = {}

    SOUL_RISKY_TAGS.each do |risky_tag|
      doc.each_element("//#{risky_tag}") do |risky_element|
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
                           child.to_s.gsub("'", '__SINGLEQUOTE__').gsub('`', '__BACKTICK__')
                         end
    end

    # Extend this for different tags with special handling
    inner_content = if risky_element.name == 's'
                      "~~#{output_segments.join}~~"
                    elsif risky_element.name == 'ins'
                      underline_name = risky_element.parent.name == 's' ? '.textulst' : '.textul'
                      "[#{output_segments.join}]{#{underline_name}}"
                    end

    # Extend this for different parent tags with special handling
    if risky_element.parent.name == 's'
      "~~#{inner_content}~~"
    else
      inner_content
    end
  end
end
