require 'spec_helper'

RSpec.describe 'display/_ai_text.html.slim', type: :view do
  let(:field) { instance_double(TranscriptionField, id: 1, label: 'First Name', input_type: 'text') }
  let(:fields) { [field] }
  let(:field_relation) { double('field_relation') }
  let(:collection) { instance_double(Collection, transcription_fields: field_relation) }
  let(:page) do
    instance_double(
      Page,
      transcription_json: { field.id.to_s => 'Ada Lovelace' },
      xml_text: '<p><span class="field__label">first name: </span>Ada Lovelace</p>'
    )
  end
  let(:ai_transcription) do
    instance_double(
      AiTranscription,
      status_finished?: true,
      transcription_json: { field.id.to_s => 'Ada Lovelace' }
    )
  end

  before do
    allow(field_relation).to receive(:includes).with(:spreadsheet_columns).and_return(field_relation)
    allow(field_relation).to receive(:order).with(:line_number, :position).and_return(fields)

    assign(:collection, collection)
    assign(:page, page)
    assign(:ai_transcription, ai_transcription)

    allow(view).to receive(:language_attrs).and_return({})
  end

  it 'renders the human diff pane from structured transcription JSON when available' do
    render partial: 'display/ai_text'

    human_pane = Capybara.string(rendered).find('[data-diff-transcription="changed"] .html-code', visible: :all)
    ai_pane = Capybara.string(rendered).find('[data-diff-transcription="original"] .html-code', visible: :all)

    expect(human_pane).to have_css('.field__label', text: 'First Name:')
    expect(human_pane).to have_text('Ada Lovelace')
    expect(human_pane).not_to have_text('first name:')
    expect(human_pane.native.inner_html.sub(/<h5>.*?<\/h5>/, '')).to eq(ai_pane.native.inner_html.sub(/<h5>.*?<\/h5>/, ''))
  end

  it 'falls back to XML for the human diff pane when structured transcription JSON is unavailable' do
    allow(page).to receive(:transcription_json).and_return({})

    allow(view).to receive(:xml_to_html).with(page.xml_text).and_return('<p>first name: Ada Lovelace</p>'.html_safe)

    render partial: 'display/ai_text'

    human_pane = Capybara.string(rendered).find('[data-diff-transcription="changed"] .html-code', visible: :all)

    expect(view).to have_received(:xml_to_html).with(page.xml_text)
    expect(human_pane).to have_text('first name: Ada Lovelace')
  end
end
