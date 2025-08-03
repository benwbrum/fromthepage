require 'spec_helper'

RSpec.describe AbstractXmlHelper, type: :helper do
  fixtures :all

  let(:user_signed_in?) { true }

  before do
    @collection = Collection.first
    @a_tag_with_attr = '<a href="http://example.com" target="_blank"> A tag with preserved target</a>'

    @xml_text = "<?xml version='1.0' encoding='UTF-8'?>    \n      <page>\n \
    #{@a_tag_with_attr}\n \
    <p>guide the reader <lb/>to the correct pron<lb break='no'/>ounciation \
    [sic].</p><p>I am Dear Sir<lb/>Yours Faith<lb break='no'>:</lb>fully<lb/>Samuel Gason</p>\n \
    </page>\n"
  end

  it "returns a <br> tag with preserve_lb=true" do
    expect(xml_to_html(@xml_text, true, true)).to include("correct pron-<br/>\nounciation")
    expect(xml_to_html(@xml_text, true, true)).to include("Faith:<br/>\nfully")
  end

  it "returns a <span> tag without a hyphen with preserve_lb=false" do
    expect(xml_to_html(@xml_text, false, true)).to include("pron<span class=\"line-break\"></span>ounciation")
    expect(xml_to_html(@xml_text, false, true)).to include("Faith<span class=\"line-break\"></span>fully")
  end

  it 'returns a <a> tag with preserved href and target attributes' do
    expect(xml_to_html(@xml_text, true, true)).to include(@a_tag_with_attr)
  end

  context "div element handling" do
    it "adds newlines before and after div elements" do
      xml_with_div = "<?xml version='1.0' encoding='UTF-8'?><page>Here is some texta div<div>another div</div>more text</page>"
      result = xml_to_html(xml_with_div, true, true)
      
      # Should have newlines before and after div
      expect(result).to include("texta div\n<div>another div</div>\nmore text")
    end

    it "handles multiple div elements correctly" do
      xml_with_divs = "<?xml version='1.0' encoding='UTF-8'?><page><p>Paragraph</p><div>First div</div><div>Second div</div><p>Another paragraph</p></page>"
      result = xml_to_html(xml_with_divs, true, true)
      
      # Should have newlines around each div
      expect(result).to include("\n<div>First div</div>\n")
      expect(result).to include("\n<div>Second div</div>\n")
    end
  end

  context "with params" do
    let(:params) { { action: "read_work" } }

    it "returns a whitespace after a hard break with preserve_lb=false" do
      expect(xml_to_html(@xml_text, false, true)).to include("guide the reader <span class=\"line-break\"> </span>to")
    end
  end
end
