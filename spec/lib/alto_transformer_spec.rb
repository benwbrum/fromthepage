require 'spec_helper'
require 'alto_transformer'

RSpec.describe AltoTransformer do
  describe '.plaintext_from_alto_xml' do
    it 'joins strings on a text line with spaces' do
      alto_xml = <<~XML
        <alto>
          <Layout>
            <Page>
              <PrintSpace>
                <TextBlock>
                  <TextLine>
                    <String CONTENT="Hello"/>
                    <String CONTENT="world"/>
                  </TextLine>
                </TextBlock>
              </PrintSpace>
            </Page>
          </Layout>
        </alto>
      XML

      expect(described_class.plaintext_from_alto_xml(alto_xml)).to eq('Hello world')
    end

    it 'joins text lines with newlines' do
      alto_xml = <<~XML
        <alto>
          <TextBlock>
            <TextLine><String CONTENT="First"/><String CONTENT="line"/></TextLine>
            <TextLine><String CONTENT="Second"/><String CONTENT="line"/></TextLine>
          </TextBlock>
        </alto>
      XML

      expect(described_class.plaintext_from_alto_xml(alto_xml)).to eq("First line\nSecond line")
    end

    it 'separates text blocks with blank lines' do
      alto_xml = <<~XML
        <alto>
          <TextBlock><TextLine><String CONTENT="First block"/></TextLine></TextBlock>
          <TextBlock><TextLine><String CONTENT="Second block"/></TextLine></TextBlock>
        </alto>
      XML

      expect(described_class.plaintext_from_alto_xml(alto_xml)).to eq("First block\n\nSecond block")
    end

    it 'normalizes whitespace inside string content' do
      alto_xml = <<~XML
        <alto>
          <TextBlock>
            <TextLine>
              <String CONTENT="  words&#10;with&#13; whitespace  "/>
            </TextLine>
          </TextBlock>
        </alto>
      XML

      expect(described_class.plaintext_from_alto_xml(alto_xml)).to eq('words with whitespace')
    end

    it 'returns an empty string when there are no text blocks' do
      expect(described_class.plaintext_from_alto_xml('<alto/>')).to eq('')
    end
  end
end
