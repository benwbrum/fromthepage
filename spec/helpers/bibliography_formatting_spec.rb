require 'spec_helper'

RSpec.describe AbstractXmlHelper, type: :helper do
  fixtures [ :collections ]

  before do
    @collection = Collection.first
  end

  describe "Bibliography formatting" do
    context "bibliography_to_html with bibliography content" do
      it "processes TEI markup in bibliography content" do
        bibliography_xml = "<bibl>Test citation with <hi rend=\"italic\">italicized title</hi> and regular text</bibl>"

        result = bibliography_to_html(bibliography_xml, true, false, @collection)

        expect(result).to include("<i>italicized title</i>")
        expect(result).to include("Test citation with")
        expect(result).to include("and regular text")
      end

      it "handles both italic and italics rend attributes" do
        bibliography_xml = "<bibl>First <hi rend=\"italic\">singular form</hi> and <hi rend=\"italics\">plural form</hi></bibl>"

        result = bibliography_to_html(bibliography_xml, true, false, @collection)

        expect(result).to include("<i>singular form</i>")
        expect(result).to include("<i>plural form</i>")
      end

      it "handles multiple bibl elements" do
        bibliography_xml = "<bibl>First citation with <hi rend=\"italic\">Book Title</hi></bibl>\n<bibl>Second citation with <hi rend=\"italic\">Another Title</hi></bibl>"

        result = bibliography_to_html(bibliography_xml, true, false, @collection)

        expect(result).to include("<i>Book Title</i>")
        expect(result).to include("<i>Another Title</i>")
        expect(result).to include("First citation")
        expect(result).to include("Second citation")
      end

      it "handles URLs in bibliography" do
        bibliography_xml = "<bibl>Citation with URL: <a href=\"https://example.com\">https://example.com</a></bibl>"

        result = bibliography_to_html(bibliography_xml, true, false, @collection)

        expect(result).to include('<a href="https://example.com">https://example.com</a>')
      end

      it "handles plain HTML content without TEI markup" do
        html_content = '<i>This</i> is a <a href="https://www.wikipedia.com">bibliography</a>.'

        result = bibliography_to_html(html_content, true, false, @collection)

        expect(result).to include('<i>This</i>')
        expect(result).to include('<a href="https://www.wikipedia.com">bibliography</a>')
        expect(result).to include('is a')
      end

      it "handles mixed plain HTML elements" do
        html_content = '<b>Bold text</b> and <em>emphasized text</em> with a <u>underlined part</u>.'

        result = bibliography_to_html(html_content, true, false, @collection)

        expect(result).to include('<b>Bold text</b>')
        expect(result).to include('<em>emphasized text</em>')
        expect(result).to include('<u>underlined part</u>')
      end

      it "handles TEI content with HTML entities" do
        tei_content = '<ab><bibl><hi rend="italic">Seventh Manuscript Census of the United States</hi> (1850), Population Schedules, Kentucky, Jefferson County, Louisville District 1, stamped p. 8. <hi rend="italic">Eighth Manuscript Census of the United States</hi> (1860), Population Schedules, Kentucky, Jefferson County, Louisville Ward 8, p. 67.  <hi rend="italic">Find A Grave</hi>, &quot;Joseph C. Baird (unknown-1881),&quot; Memorial #100674176, https://www.findagrave.com/cgi-bin/fg.cgi?page=gr&amp;GSln=baird&amp;GSfn=Joseph&amp;GSmn=c&amp;GSbyrel=all&amp;GSdyrel=all&amp;GSst=19&amp;GScnty=1044&amp;GScntry=4&amp;GSob=n&amp;GRid=100674176&amp;df=all&amp; (accessed August, 11, 2017).
</bibl></ab>'

        result = bibliography_to_html(tei_content, true, false, @collection)

        expect(result).to include('<i>Seventh Manuscript Census of the United States</i>')
        expect(result).to include('<i>Eighth Manuscript Census of the United States</i>')
        expect(result).to include('<i>Find A Grave</i>')
        expect(result).to include('"Joseph C. Baird (unknown-1881),"')
        expect(result).to include('&amp;GSln=baird')
      end

      it "handles complex TEI content with line breaks and malformed lb tags" do
        # Test case from user bug report: content with leading text, <lb> elements, and extra </lb> tags
        complex_tei = " (1850), Population Schedules, Mississippi, Wilkinson County, p. 295A.<lb>
<hi rend=\"italic\">Eighth Manuscript Census of the United States</hi> (1860), Population Schedules, Kentucky, Jefferson County, Louisville Ward 5, p. 119.<lb>
<hi rend=\"italic\">Eighth Manuscript Census of the United States</hi> (1860), Slave Schedules, Kentucky, Jefferson County, Louisville, p. 272B.<lb>
<hi rend=\"italic\">Ninth Manuscript Census of the United States</hi> (1870), Population Schedules, Mississippi, Jackson County, Hinds, p. 746B.<lb>
Henry Tanner, ed., <hi rend=\"italic\">Tanner's Louisville Directory and Business Advertiser for 1861</hi> (Louisville: Directory Publication and Advertising Agency, 1861), 227.<lb>
<hi rend=\"italic\">Biographical and Historical Memoirs of Mississippi</hi>, vol. 2, (Chicago: The Goodspeed Publishing Co., 1881), 772-775.<lb>
Find A Grave, \"Judge Horatio Fleming Simrall (1818-1901),\" Memorial 26780638, accessed May 14, 2020, https://www.findagrave.com/memorial/26780638. <lb>
G. Glenn Clift, <hi rend=\"italic\">Governors of Kentucky, 1792-1942</hi> (Cynthiana, Ky: Hobson Press, 1942), 142-43.<lb>
Robert A. Powell, <hi rend=\"italic\">Kentucky Governors</hi> (Frankfort, KY, 1976), 116.
</lb></lb></lb></lb></lb></lb></lb></lb>"

        result = bibliography_to_html(complex_tei, true, false, @collection)

        # Should render line breaks
        expect(result).to include('<br/>')
        expect(result.scan('<br/>').count).to be >= 8  # At least 8 line breaks

        # Should render italics correctly
        expect(result).to include('<i>Eighth Manuscript Census of the United States</i>')
        expect(result).to include('<i>Ninth Manuscript Census of the United States</i>')
        expect(result).to include('<i>Tanner')  # Part of the title
        expect(result).to include('<i>Biographical and Historical Memoirs of Mississippi</i>')
        expect(result).to include('<i>Governors of Kentucky, 1792-1942</i>')
        expect(result).to include('<i>Kentucky Governors</i>')

        # Should handle the leading text properly
        expect(result).to include('(1850), Population Schedules, Mississippi, Wilkinson County, p. 295A.')

        # Should handle the URLs and other content
        expect(result).to include('https://www.findagrave.com/memorial/26780638')
        expect(result).to include('Judge Horatio Fleming Simrall')
      end

      it "handles TEI content with malformed lb elements" do
        # Test various malformed lb tag scenarios
        malformed_content = "Text before <lb> more text <lb></lb> and <lb/> final text</lb></lb>"

        result = bibliography_to_html(malformed_content, true, false, @collection)

        # Should convert all to proper line breaks
        expect(result).to include('<br/>')
        expect(result).to include('Text before')
        expect(result).to include('more text')
        expect(result).to include('final text')
      end

      it "returns empty string for empty content to show edit links" do
        result = bibliography_to_html('', true, false, @collection)
        expect(result).to eq('')

        result = bibliography_to_html('   ', true, false, @collection)
        expect(result).to eq('')

        result = bibliography_to_html('<p></p>', true, false, @collection)
        expect(result).to eq('')
      end
    end
  end
end
