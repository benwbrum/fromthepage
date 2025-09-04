require 'spec_helper'

RSpec.describe AbstractXmlHelper, type: :helper do
  fixtures [ :collections ]

  before do
    @collection = Collection.first
  end

  describe "Bibliography formatting" do
    context "xml_to_html with bibliography content" do
      it "processes TEI markup in bibliography content" do
        bibliography_xml = "<bibl>Test citation with <hi rend=\"italic\">italicized title</hi> and regular text</bibl>"

        result = xml_to_html(bibliography_xml, true, false, @collection)

        expect(result).to include("<i>italicized title</i>")
        expect(result).to include("Test citation with")
        expect(result).to include("and regular text")
      end

      it "handles both italic and italics rend attributes" do
        bibliography_xml = "<bibl>First <hi rend=\"italic\">singular form</hi> and <hi rend=\"italics\">plural form</hi></bibl>"

        result = xml_to_html(bibliography_xml, true, false, @collection)

        expect(result).to include("<i>singular form</i>")
        expect(result).to include("<i>plural form</i>")
      end

      it "handles multiple bibl elements" do
        bibliography_xml = "<bibl>First citation with <hi rend=\"italic\">Book Title</hi></bibl>\n<bibl>Second citation with <hi rend=\"italic\">Another Title</hi></bibl>"

        result = xml_to_html(bibliography_xml, true, false, @collection)

        expect(result).to include("<i>Book Title</i>")
        expect(result).to include("<i>Another Title</i>")
        expect(result).to include("First citation")
        expect(result).to include("Second citation")
      end

      it "handles URLs in bibliography" do
        bibliography_xml = "<bibl>Citation with URL: <a href=\"https://example.com\">https://example.com</a></bibl>"

        result = xml_to_html(bibliography_xml, true, false, @collection)

        expect(result).to include('<a href="https://example.com">https://example.com</a>')
      end

      it "handles plain HTML content without TEI markup" do
        html_content = '<i>This</i> is a <a href="https://www.wikipedia.com">bibliography</a>.'

        result = xml_to_html(html_content, true, false, @collection)

        expect(result).to include('<i>This</i>')
        expect(result).to include('<a href="https://www.wikipedia.com">bibliography</a>')
        expect(result).to include('is a')
      end

      it "handles mixed plain HTML elements" do
        html_content = '<b>Bold text</b> and <em>emphasized text</em> with a <u>underlined part</u>.'

        result = xml_to_html(html_content, true, false, @collection)

        expect(result).to include('<b>Bold text</b>')
        expect(result).to include('<em>emphasized text</em>')
        expect(result).to include('<u>underlined part</u>')
      end

      it "handles TEI content with HTML entities" do
        tei_content = '<ab><bibl><hi rend="italic">Seventh Manuscript Census of the United States</hi> (1850), Population Schedules, Kentucky, Jefferson County, Louisville District 1, stamped p. 8. <hi rend="italic">Eighth Manuscript Census of the United States</hi> (1860), Population Schedules, Kentucky, Jefferson County, Louisville Ward 8, p. 67.  <hi rend="italic">Find A Grave</hi>, &quot;Joseph C. Baird (unknown-1881),&quot; Memorial #100674176, https://www.findagrave.com/cgi-bin/fg.cgi?page=gr&amp;GSln=baird&amp;GSfn=Joseph&amp;GSmn=c&amp;GSbyrel=all&amp;GSdyrel=all&amp;GSst=19&amp;GScnty=1044&amp;GScntry=4&amp;GSob=n&amp;GRid=100674176&amp;df=all&amp; (accessed August, 11, 2017).
</bibl></ab>'

        result = xml_to_html(tei_content, true, false, @collection)

        expect(result).to include('<i>Seventh Manuscript Census of the United States</i>')
        expect(result).to include('<i>Eighth Manuscript Census of the United States</i>')
        expect(result).to include('<i>Find A Grave</i>')
        expect(result).to include('"Joseph C. Baird (unknown-1881),"')
        expect(result).to include('&amp;GSln=baird')
      end

      it "handles XML parsing errors gracefully by falling back to HTML processing" do
        # Test with content that might cause XML parsing issues
        problematic_content = '<bibl>Citation with <hi rend="italic>Invalid XML</bibl>'

        result = xml_to_html(problematic_content, true, false, @collection)

        # Should still produce some output, even if not perfectly formatted
        expect(result).not_to be_empty
        expect(result).to include('Citation with')
      end
    end
  end
end
