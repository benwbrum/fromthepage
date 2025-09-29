require 'spec_helper'

RSpec.describe ExportHelper, type: :helper do
  fixtures [:collections]

  before do
    @collection = Collection.first
    @context = double("context", translation_mode: false)
  end

  describe "Bibliography TEI export formatting" do
    context "bibliography_to_export_tei" do
      it "processes TEI markup in bibliography for export" do
        bibliography_xml = "<bibl>Test citation with <hi rend=\"italic\">italicized title</hi> and <lb/>line break</bibl>"

        result = bibliography_to_export_tei(bibliography_xml, @context)

        expect(result).to include("<hi rend='italic'>italicized title</hi>")
        expect(result).to include("<lb/>")
        expect(result).to include("Test citation with")
      end

      it "handles complex TEI content with multiple hi and lb elements" do
        complex_tei = " (1850), Population Schedules, Kentucky.<lb>
<hi rend=\"italic\">Eighth Manuscript Census</hi> (1860), Population Schedules.<lb>
Henry Tanner, ed., <hi rend=\"italic\">Directory</hi> (Louisville, 1861), 227."

        result = bibliography_to_export_tei(complex_tei, @context)

        expect(result).to include("<hi rend='italic'>Eighth Manuscript Census</hi>")
        expect(result).to include("<hi rend='italic'>Directory</hi>")
        expect(result).to include("<lb/>")
        expect(result).to include("(1850), Population Schedules, Kentucky.")
      end

      it "returns empty string for empty content" do
        result = bibliography_to_export_tei('', @context)
        expect(result).to eq('')
      end

      it "handles malformed XML gracefully" do
        malformed_xml = "Text with <invalid>unclosed tag and <lb> tags"

        result = bibliography_to_export_tei(malformed_xml, @context)

        # Should return empty string for malformed XML in TEI export context
        expect(result).to eq('')
      end
    end
  end
end