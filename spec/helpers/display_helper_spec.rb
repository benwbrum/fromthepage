require 'spec_helper'

RSpec.describe DisplayHelper, type: :helper do
  Field = Struct.new(:id, :label, :input_type, :spreadsheet_columns)
  Column = Struct.new(:id, :label)

  class FieldCollection
    def initialize(fields)
      @fields = fields
    end

    def includes(*_args)
      self
    end

    def order(*_args)
      @fields
    end
  end

  describe '#ai_field_html' do
    it 'returns an empty html-safe string when transcription json is blank' do
      result = helper.ai_field_html({}, double(transcription_fields: FieldCollection.new([])))

      expect(result).to eq('')
      expect(result).to be_html_safe
    end

    it 'renders non-instruction fields with escaped labels and values' do
      fields = [
        Field.new(1, 'Name', 'text', []),
        Field.new(2, 'Instructions', 'instruction', []),
        Field.new(3, 'Description', 'description', [])
      ]
      collection = double(transcription_fields: FieldCollection.new(fields))

      result = helper.ai_field_html({ '1' => '<script>alert(1)</script>', '2' => 'Skip me', '3' => 'A description' }, collection)

      expect(result).to include('<span class="field__label">Name: </span>&lt;script&gt;alert(1)&lt;/script&gt;')
      expect(result).to include('<span class="field__label">Description </span>A description')
      expect(result).not_to include('Skip me')
      expect(result).to be_html_safe
    end

    it 'renders spreadsheet fields as escaped tables' do
      columns = [Column.new(10, 'Column <A>'), Column.new(11, 'Column B')]
      fields = [Field.new(4, 'Table', 'spreadsheet', columns)]
      collection = double(transcription_fields: FieldCollection.new(fields))
      transcription_json = { '4' => [{ '10' => '<cell>', '11' => 'Value B' }] }

      result = helper.ai_field_html(transcription_json, collection)

      expect(result).to include('<span class="field__label">Table: </span>')
      expect(result).to include('<table class="tabular">')
      expect(result).to include('<th>Column &lt;A&gt;</th>')
      expect(result).to include('<td>&lt;cell&gt;</td>')
      expect(result).to include('<td>Value B</td>')
    end
  end

  describe '#has_translation?' do
    it 'is true when the work supports translation and the page translation has started' do
      assign(:work, double(supports_translation: true))
      assign(:page, double(translation_status_new?: false))

      expect(helper.has_translation?).to be true
    end

    it 'is false for a new translation status' do
      assign(:work, double(supports_translation: true))
      assign(:page, double(translation_status_new?: true))

      expect(helper.has_translation?).to be false
    end
  end

  describe '#translation_mode?' do
    it 'requires a translatable work and translation param' do
      assign(:work, double(supports_translation: true))
      allow(helper).to receive(:params).and_return({ translation: 'true' })

      expect(helper.translation_mode?).to be true
    end

    it 'is false when the work does not support translation' do
      assign(:work, double(supports_translation: false))
      allow(helper).to receive(:params).and_return({ translation: 'true' })

      expect(helper.translation_mode?).to be false
    end
  end

  describe '#correction_mode?' do
    it 'returns whether the page work uses OCR correction' do
      assign(:page, double(work: double(ocr_correction: true)))

      expect(helper.correction_mode?).to be true
    end
  end
end
