# frozen_string_literal: true

require 'spec_helper'
require 'textract/alto_builder'

describe Textract::AltoBuilder do
  let(:blocks) do
    [
      {
        id: 'line-1',
        block_type: 'LINE',
        text: 'Hello world',
        geometry: {
          bounding_box: { left: 0.1, top: 0.2, width: 0.5, height: 0.05 }
        },
        relationships: [
          { type: 'CHILD', ids: %w[word-1 word-2] }
        ]
      },
      {
        id: 'word-1',
        block_type: 'WORD',
        text: 'Hello',
        confidence: 98.5,
        geometry: {
          bounding_box: { left: 0.1, top: 0.2, width: 0.18, height: 0.05 }
        }
      },
      {
        id: 'word-2',
        block_type: 'WORD',
        text: 'world',
        confidence: 97.0,
        geometry: {
          bounding_box: { left: 0.3, top: 0.2, width: 0.2, height: 0.05 }
        }
      }
    ]
  end

  subject(:builder) { described_class.new(blocks, image_width: 1000, image_height: 2000) }

  describe '#build' do
    subject(:xml_string) { builder.build }
    let(:doc) { Nokogiri::XML(xml_string) }

    it 'produces valid XML' do
      expect { doc }.not_to raise_error
    end

    it 'includes a TextLine for each LINE block' do
      expect(doc.search('TextLine').length).to eq(1)
    end

    it 'includes a String for each WORD block' do
      expect(doc.search('String').length).to eq(2)
    end

    it 'sets correct CONTENT attributes on String elements' do
      expect(doc.search('String').map { |n| n['CONTENT'] }).to eq(%w[Hello world])
    end

    it 'converts fractional bounding boxes to pixel coordinates for words' do
      word = doc.search('String').first

      # left: 0.1 * 1000 = 100
      expect(word['HPOS']).to eq('100')
      # top: 0.2 * 2000 = 400
      expect(word['VPOS']).to eq('400')
      # width: 0.18 * 1000 = 180
      expect(word['WIDTH']).to eq('180')
      # height: 0.05 * 2000 = 100
      expect(word['HEIGHT']).to eq('100')
    end

    it 'converts fractional bounding boxes to pixel coordinates for lines' do
      line = doc.search('TextLine').first

      expect(line['HPOS']).to eq('100')
      expect(line['VPOS']).to eq('400')
      expect(line['WIDTH']).to eq('500')
      expect(line['HEIGHT']).to eq('100')
    end

    it 'sets WC confidence attribute on String elements' do
      word = doc.search('String').first
      # 98.5 / 100 = 0.985
      expect(word['WC']).to eq('0.985')
    end

    it 'produces ALTO XML compatible with AltoTransformer' do
      expect(AltoTransformer.plaintext_from_alto_xml(xml_string)).to eq('Hello world')
    end

    it 'wraps all lines in a single TextBlock' do
      expect(doc.search('TextBlock').length).to eq(1)
    end

    it 'includes the softwareName Amazon Textract in the description' do
      expect(doc.at('softwareName').text).to eq('Amazon Textract')
    end

    context 'with string-keyed blocks (parsed from JSON)' do
      let(:blocks) do
        [
          {
            'id' => 'line-1',
            'block_type' => 'LINE',
            'text' => 'Test line',
            'geometry' => {
              'bounding_box' => { 'left' => 0.0, 'top' => 0.0, 'width' => 1.0, 'height' => 0.1 }
            },
            'relationships' => [
              { 'type' => 'CHILD', 'ids' => ['word-1'] }
            ]
          },
          {
            'id' => 'word-1',
            'block_type' => 'WORD',
            'text' => 'Test',
            'confidence' => 99.0,
            'geometry' => {
              'bounding_box' => { 'left' => 0.0, 'top' => 0.0, 'width' => 0.2, 'height' => 0.1 }
            }
          }
        ]
      end

      it 'handles string-keyed blocks correctly' do
        xml = described_class.new(blocks, image_width: 500, image_height: 500).build
        expect(AltoTransformer.plaintext_from_alto_xml(xml)).to eq('Test')
      end
    end

    context 'with a LINE block that has no CHILD relationships' do
      let(:blocks) do
        [
          {
            id: 'line-1',
            block_type: 'LINE',
            text: 'Orphan line',
            geometry: {
              bounding_box: { left: 0.0, top: 0.0, width: 1.0, height: 0.1 }
            },
            relationships: []
          }
        ]
      end

      it 'renders an empty TextLine without error' do
        xml = described_class.new(blocks, image_width: 1000, image_height: 1000).build
        doc = Nokogiri::XML(xml)

        expect(doc.search('TextLine').length).to eq(1)
        expect(doc.search('String').length).to eq(0)
      end
    end
  end

  describe '#initialize' do
    it 'raises if image_width is zero' do
      expect do
        described_class.new(blocks, image_width: 0, image_height: 2000)
      end.to raise_error(ArgumentError, /image_width/)
    end

    it 'raises if image_height is zero' do
      expect do
        described_class.new(blocks, image_width: 1000, image_height: 0)
      end.to raise_error(ArgumentError, /image_height/)
    end
  end
end
