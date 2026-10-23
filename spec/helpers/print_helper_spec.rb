require 'spec_helper'

RSpec.describe PrintHelper, type: :helper do
  before do
    allow(helper).to receive(:logger).and_return(double(debug: nil, error: nil))
  end

  describe '#article_to_latex' do
    it 'converts line breaks and flattens links' do
      xml = '<page><p>Hello<lb/>World <link target_title="Title" target_id="1">visible text</link></p></page>'

      result = helper.send(:article_to_latex, xml)

      expect(result).to include("Hello\nWorld")
      expect(result).to include('visible text')
      expect(result).not_to include('<link')
    end

    it 'adds paragraph spacing for multiple paragraphs' do
      xml = '<page><p>First</p><p>Second</p></page>'

      result = helper.send(:article_to_latex, xml)

      expect(result).to include("First\n \n \nSecond")
    end
  end

  describe '#xml_to_latex' do
    it 'converts page line breaks to newlines' do
      xml = '<page><p>Hello<lb/>World</p></page>'

      expect(helper.xml_to_latex(xml)).to include("Hello\nWorld")
    end

    it 'adds a footnote for a long article title when the article is missing' do
      allow(Article).to receive(:find).with('123').and_raise(ActiveRecord::RecordNotFound)
      xml = '<page><p><link target_id="123" target_title="Long Article Title">Short</link></p></page>'

      result = helper.xml_to_latex(xml)

      expect(result).to include('Short')
      expect(result).to include('\\footnote{Long Article Title}')
    end

    it 'does not repeat the same link footnote' do
      allow(Article).to receive(:find).with('123').and_raise(ActiveRecord::RecordNotFound)
      xml = '<page><p><link target_id="123" target_title="Long Article Title">Short</link> and <link target_id="123" target_title="Long Article Title">Short</link></p></page>'

      result = helper.xml_to_latex(xml)

      expect(result.scan('\\footnote{Long Article Title}').length).to eq(1)
    end
  end
end
