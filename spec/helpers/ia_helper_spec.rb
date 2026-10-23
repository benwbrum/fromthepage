require 'spec_helper'

RSpec.describe IaHelper, type: :helper do
  describe '#display_ocr' do
    it 'returns an empty string when OCR text is blank' do
      expect(helper.display_ocr(double(ocr_text: nil))).to eq('')
      expect(helper.display_ocr(double(ocr_text: ''))).to eq('')
    end

    it 'escapes angle brackets and preserves paragraph breaks' do
      result = helper.display_ocr(double(ocr_text: "A <tag>\n\nB > C"))

      expect(result).to include('A &lt;tag&gt;')
      expect(result).to include('<br /><br />')
      expect(result).to include('B &gt; C')
      expect(result).not_to include('A <tag>')
    end
  end
end
