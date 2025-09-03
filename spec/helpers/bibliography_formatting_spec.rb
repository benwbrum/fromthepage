require 'spec_helper'

RSpec.describe AbstractXmlHelper, type: :helper do
  fixtures [:collections]

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
    end
  end
end