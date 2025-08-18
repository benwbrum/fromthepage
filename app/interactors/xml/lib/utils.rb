class Xml::Lib::Utils
  STRIKETHROUGH_TAGS = ['s', 'del', 'strike'].freeze
  UNDERLINE_TAGS = ['ins', 'u'].freeze
  UNCLEAR_TAGS = ['unclear'].freeze

  SOUL_RISKY_TAGS = STRIKETHROUGH_TAGS + UNDERLINE_TAGS + UNCLEAR_TAGS

  TEI_REND_MAP = {
    'italic' => 'em',
    'bold' => 'strong',
    'underline' => 'u',
    'str' => 's',
    'u' => 'u'
  }.freeze

  # TODO: extend functionality for other problematic nested tags
  def self.handle_soul_risky_tags(doc)
    rend_to_html(doc)
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
    output = if STRIKETHROUGH_TAGS.include?(risky_element.name)
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
             elsif UNCLEAR_TAGS.include?(risky_element.name)
               "\\[#{output_segments.join}\\]"
             end

    output.gsub('~~~~', '').gsub('[]{.ul}', '')
  end

  def self.rend_to_html(doc)
    doc.each_element('//hi[@rend]') do |hi|
      rend = TEI_REND_MAP[hi['rend']]

      next unless rend.present?

      new_node = REXML::Element.new(rend)
      hi.children.each do |child|
        new_node << child
      end

      hi.parent.insert_before(hi, new_node)
      hi.remove
    end
  end
end
