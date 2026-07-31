require 'spec_helper'

RSpec.describe TranscriptionField::Lib::Utils do
  describe '.parse_fields' do
    it 'renders the field label as configured, not the parameterized form key' do
      collection = create(:collection)
      field = create(:transcription_field, :text_field,
                      collection: collection,
                      label: '1. Please provide a listing of activities and programs:')
      work = create(:work)
      page = create(:page, work: work)

      field_cells = {
        field.id.to_s => { field.label.parameterize => 'Some transcribed value' }
      }

      TranscriptionField::Lib::Utils.parse_fields(page: page, field_cells: field_cells)

      expect(page.source_text).to include(
        '<span class="field__label">1. Please provide a listing of activities and programs:: </span>Some transcribed value'
      )
      expect(page.source_text).not_to include('1-please-provide-a-listing')
    end
  end
end
