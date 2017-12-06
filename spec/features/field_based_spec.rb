
require 'spec_helper'

describe "collection settings js tasks", :order => :defined do
  Capybara.javascript_driver = :webkit

  before :all do
    @owner = User.find_by(login: OWNER)
    @collections = @owner.all_owner_collections
    @collection = @collections.second
  end

  before :each do
    login_as(@owner, :scope => :user)
  end    

  it "sets collection to field based transcription" do
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Settings")
    page.click_link("Enable Field Based Transcription")
    expect(page).to have_selector('a', text: 'Edit Fields')
    page.find('.sidecol').click_link('Edit Fields')
    expect(page).to have_content("Edit Transcription Fields")
  end

  it "edits fields for transcription" do
    expect(TranscriptionField.all.count).to eq 0
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Edit Fields")
    page.find('#new-fields tbody tr[1]').fill_in('transcription_fields__line_number', with: 1)
    page.find('#new-fields tbody tr[1]').fill_in('transcription_fields__label', with: 'First field')
    page.find('#new-fields tbody tr[2]').fill_in('transcription_fields__line_number', with: 1)
    page.find('#new-fields tbody tr[2]').fill_in('transcription_fields__label', with: 'Second field')
    page.find('#new-fields tbody tr[2]').select('textarea', from: 'transcription_fields__input_type')
    #page.find('#new-fields tbody tr[3]').fill_in('transcription_fields__line_number', with: 2)
    #page.find('#new-fields tbody tr[3]').fill_in('transcription_fields__label', with: 'Third field')
    #page.find('#new-fields tbody tr[3]').select('select', from: 'transcription_fields__input_type')
    click_button 'Save'
    expect(TranscriptionField.all.count).to eq 2
  end


  it "adds fields for transcription", :js => true do
    count = page.all('#new-fields tbody tr').count
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Edit Fields")
    click_button 'Add Additional Field'
    expect(page.all('#new-fields tbody tr').count).to be > count
  end

  it "sets collection back to document based transcription" do
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Settings")
    page.click_link("Revert to Document Based Transcription")
    expect(page).not_to have_selector('a', text: 'Edit Fields')
  end

end
