# Shared normalization for bibliography editing and TEI export. Never repair
# structural errors: an unbalanced tag needs the editor's attention.
class BibliographyXml
  def self.normalize(text)
    xml = text.gsub(/<!\[CDATA\[.*?\]\]>|<!--.*?-->|<[^>]+>/m) do |tag|
      next tag if tag.start_with?('<![CDATA[', '<!--')

      tag.gsub(/(\s[\w:.-]+\s*=\s*)("[^"]*"|'[^']*'|[“”][^“”]*[“”]|[‘’][^‘’]*[‘’])/) do
        assignment = Regexp.last_match(1)
        value = Regexp.last_match(2)
        if value.start_with?('“', '”')
          "#{assignment}\"#{value[1...-1].gsub('"', '&quot;')}\""
        elsif value.start_with?('‘', '’')
          "#{assignment}'#{value[1...-1].gsub("'", '&apos;')}'"
        else
          "#{assignment}#{value}"
        end
      end
    end
    # Preserve XML entities, comments and CDATA; escape prose/URL ampersands.
    xml = xml.gsub(/<!\[CDATA\[.*?\]\]>|<!--.*?-->|&(?!(?:amp|lt|gt|quot|apos|#\d+|#x[0-9a-fA-F]+);)/m) do |match|
      match == '&' ? '&amp;' : match
    end
    xml = xml.gsub(/<(lb|br|hr)(\s[^<>]*?)?>\s*<\/\1>/, '<\1\2/>')
    xml.gsub(/<(lb|br|hr)(\s[^<>]*?)?(?<!\/)>/, '<\1\2/>')
  end

  def self.parse(text)
    xml = "<root>#{normalize(text)}</root>"
    Nokogiri::XML(xml) { |config| config.strict.nonet }
    xml
  end
end
