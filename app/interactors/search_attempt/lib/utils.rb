class SearchAttempt::Lib::Utils
  def self.highlight_terms(transcription, search_string)
    doc = Nokogiri::HTML::fragment(transcription)
    words_regex = /\b(#{search_string.split(' ').join('|')})\b/i

    doc.traverse do |node|
      if node.text? && node.parent.name != 'script'
        node.replace(
          node.text.gsub(words_regex) do |match|
            "<span class=\"highlighted\">#{match}</span>"
          end
        )
      end
    end

    doc.to_html.html_safe
  end
end
