require 'spec_helper'

describe TranscriptionFieldHelper, type: :helper do
  it 'uses title-case English labels while preserving metadata type values and order' do
    I18n.with_locale(:en) do
      options = helper.field_input_type_options(TranscriptionField::METADATA_INPUTS)
      expect(options.map(&:first)).to eq(['Text', 'Select', 'Date', 'Multiselect', 'Text Area', 'Instruction', 'Alt Text', 'Subject Headings (LCSH)'])
      expect(options.map(&:last)).to eq(TranscriptionField::METADATA_INPUTS)
    end
  end

  %i[en es pt fr de].each do |locale|
    it "translates all transcription, metadata and spreadsheet types in #{locale}" do
      types = (TranscriptionField::TRANSCRIPTION_INPUTS + TranscriptionField::METADATA_INPUTS + SpreadsheetColumn::INPUTS).uniq
      I18n.with_locale(locale) do
        options = helper.field_input_type_options(types)
        expect(options.map(&:last)).to eq(types)
        types.zip(options).each do |type, option|
          expect(option.first).to eq(I18n.t("transcription_field.input_types.#{type.tr(' ', '_')}", locale: locale, fallback: false, raise: true))
        end
      end
    end
  end

  it 'uses the selected locale instead of English labels' do
    I18n.with_locale(:es) do
      expect(helper.field_input_type_options(%w[text date])).to eq([['Texto', 'text'], ['Fecha', 'date']])
    end
  end
end
