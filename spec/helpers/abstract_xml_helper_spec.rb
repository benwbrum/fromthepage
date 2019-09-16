require 'spec_helper'

RSpec.describe AbstractXmlHelper, type: :helper do
  fixtures :all

  let(:user_signed_in?) { true }

  before do
    @collection = Collection.first

    @xml_text = "<?xml version='1.0' encoding='UTF-8'?>    \n      <page>\n \
    <p>guide the reader <lb/>to the correct pron<lb break='no'/>ounciation \
    [sic].</p><p>I am Dear Sir<lb/>Yours Faithfully<lb/>Samuel Gason</p>\n \
    </page>\n"
  end

  it "returns a <br> tag with preserve_lb=true" do
    expect(xml_to_html(@xml_text, true, true)).to include("correct pron<br/>\nounciation")
  end

  it "returns a <span> tag with a hyphen with preserve_lb=false" do
    expect(xml_to_html(@xml_text, false, true)).to include("pron<span class='line-break'>-</span>ounciation")
  end

  context "with params" do
    let(:params) { { action: "read_work" } }

    it "adds a whitespace after a hard break with preserve_lb=false" do
      expect(xml_to_html(@xml_text, false, true)).to include("guide the reader <span class='line-break'> </span>to")
    end
  end
end
