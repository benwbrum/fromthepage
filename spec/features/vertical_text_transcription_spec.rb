require 'spec_helper'

describe "vertical text transcription", :order => :defined do
  
  before :all do
    @owner = User.find_by(login: OWNER)
    @user = User.find_by(login: USER)
    @collections = @owner.all_owner_collections
    @collection = @collections.second
    @work = @collection.works.second
    @page = @work.pages.first
  end

  it "applies vertical writing mode CSS classes for vertical-rl orientation", js: true do
    # Set collection to vertical-rl orientation
    @collection.update(text_orientation: 'vertical-rl')
    
    login_as(@owner, :scope => :user)
    visit collection_transcribe_page_path(@collection.owner, @collection, @work, @page)

    # Check that the text area has the correct data attribute
    expect(page).to have_css('textarea[data-writing-mode="vertical-rl"]')
    
    # Check that the preview area has the correct data attribute
    expect(page).to have_css('.page-preview[data-writing-mode="vertical-rl"]')
    
    # Check that the CodeMirror wrapper has the vertical-rl class
    # Note: This may need to wait for CodeMirror to initialize
    sleep 2
    expect(page).to have_css('.CodeMirror.vertical-rl')
  end

  it "applies vertical writing mode CSS classes for vertical-lr orientation", js: true do
    # Set collection to vertical-lr orientation
    @collection.update(text_orientation: 'vertical-lr')
    
    login_as(@owner, :scope => :user)
    visit collection_transcribe_page_path(@collection.owner, @collection, @work, @page)

    # Check that the text area has the correct data attribute
    expect(page).to have_css('textarea[data-writing-mode="vertical-lr"]')
    
    # Check that the preview area has the correct data attribute
    expect(page).to have_css('.page-preview[data-writing-mode="vertical-lr"]')
    
    # Check that the CodeMirror wrapper has the vertical-lr class
    sleep 2
    expect(page).to have_css('.CodeMirror.vertical-lr')
  end

  it "applies horizontal writing mode for standard orientations", js: true do
    # Set collection to standard ltr orientation
    @collection.update(text_orientation: 'ltr')
    
    login_as(@owner, :scope => :user)
    visit collection_transcribe_page_path(@collection.owner, @collection, @work, @page)

    # Check that the text area has the correct data attribute
    expect(page).to have_css('textarea[data-writing-mode="horizontal-tb"]')
    
    # Check that the preview area has the correct data attribute
    expect(page).to have_css('.page-preview[data-writing-mode="horizontal-tb"]')
    
    # Check that the CodeMirror wrapper has the horizontal-tb class
    sleep 2
    expect(page).to have_css('.CodeMirror.horizontal-tb')
  end

  it "includes vertical layout options in the layout dropdown", js: true do
    @collection.update(text_orientation: 'vertical-rl')
    
    login_as(@owner, :scope => :user)
    visit collection_transcribe_page_path(@collection.owner, @collection, @work, @page)

    # Click on the layout dropdown
    page.find('.dropdown dt').click
    
    # Check that vertical options are available
    expect(page).to have_content('Vertical (Right-to-Left)')
    expect(page).to have_content('Vertical (Left-to-Right)')
  end

  after :all do
    # Reset collection orientation
    @collection.update(text_orientation: 'ltr')
  end
end