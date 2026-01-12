require 'spec_helper'

RSpec.describe AbstractXmlHelper, type: :helper do
  fixtures [:collections]

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

  context "XML entity handling" do
    it "displays &lt; entity as < sign" do
      xml_with_lt = "<?xml version='1.0' encoding='UTF-8'?><page><p>Here is a &lt; sign</p></page>"
      result = xml_to_html(xml_with_lt, true, true)
      expect(result).to include("Here is a &lt; sign")
    end

    it "displays &gt; entity as > sign" do
      xml_with_gt = "<?xml version='1.0' encoding='UTF-8'?><page><p>Here is a &gt; sign</p></page>"
      result = xml_to_html(xml_with_gt, true, true)
      expect(result).to include("Here is a &gt; sign")
    end

    it "displays &amp; entity correctly" do
      xml_with_amp = "<?xml version='1.0' encoding='UTF-8'?><page><p>Here is an &amp; sign</p></page>"
      result = xml_to_html(xml_with_amp, true, true)
      expect(result).to include("Here is an &amp; sign")
    end

    it "displays &quot; entity correctly" do
      xml_with_quot = "<?xml version='1.0' encoding='UTF-8'?><page><p>Here is a &quot;quote&quot;</p></page>"
      result = xml_to_html(xml_with_quot, true, true)
      expect(result).to include('Here is a "quote"')
    end

    it "displays &apos; entity correctly" do
      xml_with_apos = "<?xml version='1.0' encoding='UTF-8'?><page><p>Here is an &apos;apostrophe&apos;</p></page>"
      result = xml_to_html(xml_with_apos, true, true)
      expect(result).to include("Here is an 'apostrophe'")
    end

    it "handles multiple XML entities in the same text" do
      xml_with_multiple = "<?xml version='1.0' encoding='UTF-8'?><page><p>Comparison: 5 &lt; 10 &amp; 10 &gt; 5</p></page>"
      result = xml_to_html(xml_with_multiple, true, true)
      expect(result).to include("Comparison: 5 &lt; 10 &amp; 10 &gt; 5")
    end

    it "handles XML entities within markdown tables" do
      xml_with_table = "<?xml version='1.0' encoding='UTF-8'?><page><table class=\"tabular\">\n<thead>\n<tr><th>Operator</th> <th>Meaning</th></tr></thead><tbody><tr><td>5 &lt; 10</td> <td>Less than</td> </tr><tr><td>10 &gt; 5</td> <td>Greater than</td> </tr></tbody></table></page>"
      result = xml_to_html(xml_with_table, true, true)
      expect(result).to include("5 &lt; 10")
      expect(result).to include("10 &gt; 5")
    end
  end
end
