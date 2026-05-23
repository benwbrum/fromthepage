require 'spec_helper'

describe AiTranscription::Lib::FieldBasedPromptBuilder do
  let!(:owner)      { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, :field_based, owner_user_id: owner.id) }
  let!(:text_field) do
    create(:transcription_field, :text_field,
           label: 'Name', collection: collection, position: 1, line_number: 1)
  end
  let!(:select_field) do
    create(:transcription_field, :select_field,
           label: 'County', options: 'Beaver;Box Elder;Cache',
           collection: collection, position: 2, line_number: 2)
  end
  let!(:date_field) do
    create(:transcription_field, :date_field,
           label: 'Birth Date', collection: collection, position: 3, line_number: 3)
  end
  let!(:description_field) do
    create(:transcription_field, :description_field,
           label: 'Fill out carefully', collection: collection, position: 4, line_number: 4)
  end
  let!(:instruction_field) do
    create(:transcription_field, :instruction_field,
           label: 'Enter county name', collection: collection, position: 5, line_number: 5)
  end

  subject(:prompt) { described_class.new(collection: collection).build }

  it 'includes each data field ID in the prompt' do
    expect(prompt).to include(text_field.id.to_s)
    expect(prompt).to include(select_field.id.to_s)
    expect(prompt).to include(date_field.id.to_s)
  end

  it 'includes field labels in the prompt' do
    expect(prompt).to include('Name')
    expect(prompt).to include('County')
    expect(prompt).to include('Birth Date')
  end

  it 'includes select options' do
    expect(prompt).to include('Beaver')
    expect(prompt).to include('Box Elder')
    expect(prompt).to include('Cache')
  end

  it 'excludes description fields' do
    expect(prompt).not_to include('Fill out carefully')
  end

  it 'excludes instruction fields' do
    expect(prompt).not_to include('Enter county name')
  end

  it 'includes an example JSON structure keyed by field ID' do
    expect(prompt).to include("\"#{text_field.id}\"")
    expect(prompt).to include("\"#{select_field.id}\"")
    expect(prompt).to include("\"#{date_field.id}\"")
  end

  context 'with a spreadsheet field' do
    let!(:spreadsheet_field) do
      create(:transcription_field, :spreadsheet_field,
             label: 'Witnesses', collection: collection, position: 6, line_number: 6)
    end
    let!(:col1) { create(:spreadsheet_column, label: 'First Name', transcription_field: spreadsheet_field, position: 1) }
    let!(:col2) { create(:spreadsheet_column, label: 'Last Name',  transcription_field: spreadsheet_field, position: 2) }

    it 'includes the spreadsheet field in the prompt' do
      expect(prompt).to include('Witnesses')
    end

    it 'includes column labels' do
      expect(prompt).to include('First Name')
      expect(prompt).to include('Last Name')
    end

    it 'includes column IDs in the example JSON' do
      expect(prompt).to include(col1.id.to_s)
      expect(prompt).to include(col2.id.to_s)
    end
  end
end
