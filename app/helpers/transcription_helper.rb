module TranscriptionHelper
	def highlight_search_terms(transcription, search_string)
		terms = search_string.scan(/"([^"]+)"/).flatten.map(&:downcase)
		terms.each do |term|
			transcription.sub!(/#{Regexp.escape(term)}/i, '<span class="highlighted">\0</span>')
		end
		transcription.html_safe
	end
end
  