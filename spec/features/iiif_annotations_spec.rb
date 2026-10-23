# frozen_string_literal: true

require 'spec_helper'

describe 'IIIF Annotations API' do
  before do
    DatabaseCleaner.start
  end

  after do
    DatabaseCleaner.clean
  end

  let(:owner) { create(:unique_user, :owner) }
  let(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let(:work) { create(:work, collection: collection, owner: owner) }
  let(:work_page) do
    create(
      :page,
      work: work,
      xml_text: annotation_xml('Isolated transcription annotation'),
      xml_translation: annotation_xml('Isolated translation annotation')
    )
  end

  it 'returns the transcription annotation as HTML' do
    visit collection_annotation_page_transcription_html_path(owner, collection, work, work_page)

    expect(page.status_code).to eq(200)
    expect(page.response_headers['Content-Type']).to start_with('text/html')
    expect(page).to have_content('Isolated transcription annotation')
  end

  it 'returns the translation annotation as HTML' do
    visit collection_annotation_page_translation_html_path(owner, collection, work, work_page)

    expect(page.status_code).to eq(200)
    expect(page.response_headers['Content-Type']).to start_with('text/html')
    expect(page).to have_content('Isolated translation annotation')
  end

  def annotation_xml(text)
    %(<?xml version="1.0" encoding="UTF-8"?><page><p>#{text}</p></page>)
  end
end
