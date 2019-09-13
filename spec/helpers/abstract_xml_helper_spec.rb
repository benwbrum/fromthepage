require 'spec_helper'

RSpec.describe AbstractXmlHelper, type: :helper do
  include DeviseHelper

  fixtures :all

  before do
    @collection = Collection.first
  end

  it "returns a <br> tag with preserve_lb=true" do
    xml_text = "<?xml version='1.0' encoding='UTF-8'?>    \n      <page>\n        <p>guide the reader <lb/>to the correct pron<lb break='no'/>ounciation [sic].</p><p>I am Dear Sir<lb/>Yours Faithfully<lb/>Samuel Gason</p>\n      </page>\n"
    expect(xml_to_html(xml_text, true, true)).to include("correct pron<br/>\nounciation")
  end

  it "returns a <span> tag and a hyphen with preserve_lb=false" do
    xml_text = "<?xml version='1.0' encoding='UTF-8'?>    \n      <page>\n        <p>guide the reader <lb/>to the correct pron<lb break='no'/>ounciation [sic].</p><p>I am Dear Sir<lb/>Yours Faithfully<lb/>Samuel Gason</p>\n      </page>\n"
    expect(xml_to_html(xml_text, false, true)).to include("pron<span class='line-break'>-</span>ounciation")
  end
end
