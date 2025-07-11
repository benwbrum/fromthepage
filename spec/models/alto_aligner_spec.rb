require 'spec_helper'

RSpec.describe AltoAligner do
  describe '.corrected_alto_xml' do
    it 'replaces OCR words with words from verbatim transcription' do
      page = build(:page, :transcribed)
      allow(page).to receive(:has_alto?).and_return(true)
      alto = <<~XML
        <alto>
          <Layout>
            <Page>
              <PrintSpace>
                <TextBlock>
                  <TextLine>
                    <String CONTENT="Helo" HPOS="10" VPOS="10" WIDTH="30" HEIGHT="10"/>
                    <String CONTENT="world" HPOS="50" VPOS="10" WIDTH="30" HEIGHT="10"/>
                  </TextLine>
                </TextBlock>
              </PrintSpace>
            </Page>
          </Layout>
        </alto>
      XML
      allow(page).to receive(:alto_xml).and_return(alto)
      allow(page).to receive(:verbatim_transcription_plaintext).and_return('Hello world')

      new_xml = AltoAligner.corrected_alto_xml(page)
      doc = Nokogiri::XML(new_xml)
      words = doc.xpath('//String').map { |s| s['CONTENT'] }
      expect(words).to eq(['Hello', 'world'])
    end
  end
end
