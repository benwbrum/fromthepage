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

  context "double-escaped XML entity handling" do
    it "fixes double-escaped &lt; entity" do
      xml_with_double_escaped = "<?xml version='1.0' encoding='UTF-8'?><page><p>Here is a &amp;lt; sign</p></page>"
      result = xml_to_html(xml_with_double_escaped, true, true)
      expect(result).to include("Here is a &lt; sign")
      expect(result).not_to include("&amp;lt;")
    end

    it "fixes double-escaped &gt; entity" do
      xml_with_double_escaped = "<?xml version='1.0' encoding='UTF-8'?><page><p>Here is a &amp;gt; sign</p></page>"
      result = xml_to_html(xml_with_double_escaped, true, true)
      expect(result).to include("Here is a &gt; sign")
      expect(result).not_to include("&amp;gt;")
    end

    it "fixes double-escaped &quot; entity" do
      xml_with_double_escaped = "<?xml version='1.0' encoding='UTF-8'?><page><p>Here is a &amp;quot;quote&amp;quot;</p></page>"
      result = xml_to_html(xml_with_double_escaped, true, true)
      expect(result).to include('Here is a &quot;quote&quot;')
      expect(result).not_to include("&amp;quot;")
    end

    it "fixes double-escaped &apos; entity" do
      xml_with_double_escaped = "<?xml version='1.0' encoding='UTF-8'?><page><p>Here is an &amp;apos;apostrophe&amp;apos;</p></page>"
      result = xml_to_html(xml_with_double_escaped, true, true)
      expect(result).to include("Here is an &apos;apostrophe&apos;")
      expect(result).not_to include("&amp;apos;")
    end

    it "fixes multiple double-escaped entities in the same text" do
      xml_with_double_escaped = "<?xml version='1.0' encoding='UTF-8'?><page><p>Comparison: 5 &amp;lt; 10 &amp;amp; 10 &amp;gt; 5</p></page>"
      result = xml_to_html(xml_with_double_escaped, true, true)
      expect(result).to include("Comparison: 5 &lt; 10 &amp; 10 &gt; 5")
      expect(result).not_to include("&amp;lt;")
      expect(result).not_to include("&amp;gt;")
    end

    it "fixes double-escaped entities within markdown tables" do
      xml_with_double_escaped = "<?xml version='1.0' encoding='UTF-8'?><page><table class=\"tabular\">\n<thead>\n<tr><th>Operator</th> <th>Meaning</th></tr></thead><tbody><tr><td>5 &amp;lt; 10</td> <td>Less than</td> </tr><tr><td>10 &amp;gt; 5</td> <td>Greater than</td> </tr></tbody></table></page>"
      result = xml_to_html(xml_with_double_escaped, true, true)
      expect(result).to include("5 &lt; 10")
      expect(result).to include("10 &gt; 5")
      expect(result).not_to include("&amp;lt;")
      expect(result).not_to include("&amp;gt;")
    end

    it "preserves correctly-escaped entities" do
      xml_with_correct = "<?xml version='1.0' encoding='UTF-8'?><page><p>Already correct: &lt; &gt; &amp;</p></page>"
      result = xml_to_html(xml_with_correct, true, true)
      expect(result).to include("Already correct: &lt; &gt; &amp;")
    end
  end

  context "indent element handling" do
    it "converts indent elements to styled spans when preserve_lb=true" do
      xml_with_indent = "<?xml version='1.0' encoding='UTF-8'?><page><p><indent spaces=\"3\"/>This is indented</p></page>"
      result = xml_to_html(xml_with_indent, true, false, @collection)

      expect(result).to include('<span class="indent" style="padding-left:1.5em;">')
      expect(result).to include('This is indented')
    end

    it "converts indent elements to single space when preserve_lb=false" do
      xml_with_indent = "<?xml version='1.0' encoding='UTF-8'?><page><p>Preceding Line\n<indent spaces=\"3\"/>This is indented</p></page>"
      result = xml_to_html(xml_with_indent, false, false, @collection)

      # Should contain a single space where the indent was
      expect(result).to include(' This is indented')
      # Should not contain the indent span
      expect(result).not_to include('class="indent"')
    end

    it "handles different indent sizes correctly" do
      xml_with_indents = "<?xml version='1.0' encoding='UTF-8'?><page><p><indent spaces=\"2\"/>Two spaces<lb/><indent spaces=\"5\"/>Five spaces</p></page>"
      result = xml_to_html(xml_with_indents, true, false, @collection)

      expect(result).to include('padding-left:1.0em;')
      expect(result).to include('padding-left:2.5em;')
    end

    it "handles multiple indented lines in a paragraph" do
      xml_with_multiple = "<?xml version='1.0' encoding='UTF-8'?><page><p><indent spaces=\"4\"/>Line one<lb/><indent spaces=\"4\"/>Line two</p></page>"
      result = xml_to_html(xml_with_multiple, true, false, @collection)

      # Should have two indent spans
      expect(result.scan(/padding-left:2\.0em;/).length).to eq(2)
    end
  end
end
