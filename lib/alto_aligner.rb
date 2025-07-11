module AltoAligner
  # Produce new ALTO XML for a page by replacing the OCR words with
  # the words from the page's verbatim transcription.  The original
  # word bounding boxes are preserved.
  #
  # The algorithm first finds uniquely occurring words in both the OCR
  # text and the corrected text. These unique words are used as anchor
  # points to recursively align the two word lists. Remaining segments
  # without anchors are aligned sequentially.
  def self.corrected_alto_xml(page)
    raise ArgumentError, 'page must be transcribed' unless page.status_transcribed?
    raise ArgumentError, 'page must have ALTO XML' unless page.has_alto?

    doc = Nokogiri::XML(page.alto_xml)
    string_nodes = doc.xpath('//String')
    ocr_words = string_nodes.map { |s| s['CONTENT'] }
    corrected_words = page.verbatim_transcription_plaintext.split(/\s+/)

    mapping = align_words(ocr_words, corrected_words)
    mapping.each do |ocr_idx, cor_idx|
      next if ocr_idx.nil? || cor_idx.nil?
      next unless string_nodes[ocr_idx] && corrected_words[cor_idx]
      string_nodes[ocr_idx]['CONTENT'] = corrected_words[cor_idx]
    end

    doc.to_xml
  end

  class << self
    private

    def align_words(ocr_words, corrected_words)
      align_span(ocr_words, corrected_words, 0, 0)
    end

    def align_span(ocr, cor, off_ocr, off_cor)
      return [] if ocr.empty? || cor.empty?

      anchors = unique_anchors(ocr, cor, off_ocr, off_cor)
      if anchors.empty?
        len = [ocr.length, cor.length].min
        return (0...len).map { |i| [off_ocr + i, off_cor + i] }
      end

      mapping = []
      last_o = 0
      last_c = 0
      anchors.each do |ao, ac|
        mapping.concat(align_span(ocr[last_o...ao - off_ocr], cor[last_c...ac - off_cor], off_ocr + last_o, off_cor + last_c))
        mapping << [ao, ac]
        last_o = ao - off_ocr + 1
        last_c = ac - off_cor + 1
      end
      mapping.concat(align_span(ocr[last_o..-1] || [], cor[last_c..-1] || [], off_ocr + last_o, off_cor + last_c))
      mapping
    end

    def unique_anchors(ocr, cor, off_o, off_c)
      ocr_pos = Hash.new { |h, k| h[k] = [] }
      ocr.each_with_index { |w, i| ocr_pos[w] << i }
      cor_pos = Hash.new { |h, k| h[k] = [] }
      cor.each_with_index { |w, i| cor_pos[w] << i }

      anchors = []
      ocr_pos.each do |w, pos|
        next unless pos.length == 1 && cor_pos[w]&.length == 1
        anchors << [pos.first + off_o, cor_pos[w].first + off_c]
      end
      anchors.sort_by(&:first)
    end
  end
end
