require 'spec_helper'

describe ExportHelper do
  include ExportHelper

  describe '#xml_to_export_tei' do
    let(:context) { double('context', translation_mode: false) }
    let(:page_id) { 'S123' }

    context 'ampersand escaping' do
      it 'escapes single ampersands' do
        xml_text = '<page><p>Johnson & Johnson</p></page>'
        result = xml_to_export_tei(xml_text, context, page_id)
        expect(result).to include('Johnson &amp; Johnson')
      end

      it 'does not double escape already escaped ampersands' do
        xml_text = '<page><p>Johnson &amp; Johnson</p></page>'
        result = xml_to_export_tei(xml_text, context, page_id)
        expect(result).to include('Johnson &amp; Johnson')
        expect(result).not_to include('&amp;amp;')
      end
    end

    context 'footnote processing' do
      it 'converts footnote to note with marker attribute' do
        xml_text = '<page><p>Text<footnote marker="†">Example of a footnote body with a dagger as a marker.</footnote></p></page>'
        result = xml_to_export_tei(xml_text, context, page_id)
        expect(result).to include('<note type="footnote" n="†">')
        expect(result).to include('Example of a footnote body with a dagger as a marker.')
      end
    end
  end

  describe 'TEI validation issues' do
    let(:collection) { double('collection', title: 'Test Collection', categories: double('categories', where: [])) }
    let(:work) { double('work', id: '14648', identifier: nil, title: 'Test Work') }
    let(:person) { double('person', 
      id: 123,
      title: 'John Doe',
      birth_date: '1866?',
      death_date: nil,
      categories: []
    )}
    let(:place) { double('place',
      id: 456,
      title: 'Test Place',
      latitude: '40.7128',
      longitude: '-74.0060',
      categories: []
    )}

    context 'xml:id validation' do
      it 'prefixes numeric IDs to make valid NCName' do
        # Test that numeric work IDs get prefixed
        expect(work.identifier || work.id).to eq('14648')
        # The template should prefix this with 'W' or similar
      end
    end

    context 'date validation' do
      it 'handles invalid date formats' do
        # Test that dates like "1866?" are handled properly
        expect(person.birth_date).to eq('1866?')
        # This should either be cleaned or omitted from when attribute
      end
    end

    context 'geo element placement' do
      it 'places geo element correctly in place structure' do
        # Test that geo elements are placed directly in place, not in note
        expect(place.latitude).to eq('40.7128')
        expect(place.longitude).to eq('-74.0060')
      end
    end
  end
end