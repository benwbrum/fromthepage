# frozen_string_literal: true

require 'spec_helper'

describe 'Metadata Description' do
  before do
    login_as(owner, scope: :user)
    visit '/feature/description/enable'
  end

  after do
    collection.destroy!
    owner.destroy!
  end

  let(:owner) { create(:unique_user, :owner) }
  let(:collection) do
    create(
      :collection,
      owner_user_id: owner.id,
      works: [],
      data_entry_type: Collection::DataEntryType::TEXT_ONLY
    )
  end

  it 'enables and disables metadata description', js: true do
    visit edit_collection_path(owner, collection)
    page.find('.side-tabs').click_link('Task Configuration')
    page.check('Enable metadata description')

    expect(page).to have_content('Collection has been updated')
    expect(page).to have_checked_field('Enable metadata description')
    expect(page.find('#metadata-fields-edit')[:disabled]).to be_nil
    expect(collection.reload.data_entry_type).to eq(Collection::DataEntryType::TEXT_AND_METADATA)

    visit edit_collection_path(owner, collection)
    page.find('.side-tabs').click_link('Task Configuration')
    page.uncheck('Enable metadata description')

    expect(page).to have_content('Collection has been updated')
    expect(page).to have_unchecked_field('Enable metadata description')
    expect(page.find('#metadata-fields-edit')[:disabled]).to eq('disabled')
    expect(collection.reload.data_entry_type).to eq(Collection::DataEntryType::TEXT_ONLY)
  end

  it 'edits description fields', js: true do
    visit edit_collection_path(owner, collection)
    page.find('.side-tabs').click_link('Task Configuration')
    page.check('Enable metadata description')

    expect(page).to have_content('Collection has been updated')
    expect(page).to have_checked_field('Enable metadata description')
    expect(collection.reload).to be_metadata_entry

    visit collection_path(owner, collection)
    page.find('.tabs').click_link('Metadata Fields')

    within '#new-fields tr:nth-child(3)' do
      fill_in 'transcription_fields__label', with: 'First metadata field'
      fill_in 'transcription_fields__percentage', with: 20
    end
    within '#new-fields tr:nth-child(4)' do
      fill_in 'transcription_fields__label', with: 'Second metadata field'
      select 'textarea', from: 'transcription_fields__input_type'
    end
    within '#new-fields tr:nth-child(5)' do
      fill_in 'transcription_fields__label', with: 'Third metadata field'
      select 'select', from: 'transcription_fields__input_type'
    end

    expect(collection.metadata_fields).to be_empty
    click_button 'Save'

    expect(page).to have_content('Select fields must have an options list.')

    metadata_fields = collection.metadata_fields.order(:id).reload
    expect(metadata_fields.count).to eq(3)
    expect(metadata_fields.map(&:label)).to eq(
      ['First metadata field', 'Second metadata field', 'Third metadata field']
    )
    expect(metadata_fields.map(&:field_type)).to all(eq(TranscriptionField::FieldType::METADATA))
    expect(metadata_fields.first.percentage).to eq(20)
    expect(metadata_fields.second.input_type).to eq('textarea')
    expect(metadata_fields.third.input_type).to eq('text')

    expect(page.find('div.fields-preview')).to have_content('First metadata field')
    expect(page.find('div.fields-preview')).to have_content('Second metadata field')
    expect(page.find('div.fields-preview')).to have_content('Third metadata field')
    expect(page.find('div.fields-preview .field-wrapper:nth-child(1)')[:style]).to eq('width: 20%;')
    expect(page.find('div.fields-preview .field-wrapper:nth-child(2)')[:style]).not_to eq('width: 20%;')
  end
end
