require 'spec_helper'

describe "subject link accessibility", :order => :defined do

  before :all do
    @owner = User.find_by(login: OWNER)
    @collections = @owner.all_owner_collections
    @collection = @collections.first
    @work = @collection.works.second
    @page = @work.pages.third
    @title = @page.title
  end

  before :each do
    login_as(@owner, :scope => :user)
  end

  it "creates subject links with proper accessibility attributes", js: true do
    visit collection_read_work_path(@work.collection.owner, @work.collection, @work)
    page.find('.work-page_title', text: @title).click_link(@title)
    page.find('.tabs').click_link("Transcribe")
    
    # Add subject links
    fill_in_editor_field("[[Test Subject]] mentioned in this document.")
    find('#save_button_top').click
    
    # Check that subject links have proper ARIA attributes
    page.find('.tabs').click_link("Overview")
    expect(page).to have_selector('a[data-controller="tooltip"]', text: 'Test Subject')
    
    subject_link = page.find('a[data-controller="tooltip"]', text: 'Test Subject')
    expect(subject_link['aria-describedby']).not_to be_nil
    expect(subject_link['tabindex']).to eq('0')
  end

  it "shows tooltip on focus for keyboard accessibility", js: true do
    visit collection_read_work_path(@work.collection.owner, @work.collection, @work)
    page.find('.work-page_title', text: @title).click_link(@title)
    
    # Use Tab key to focus on subject link
    subject_link = page.find('a[data-controller="tooltip"]', text: 'Test Subject')
    subject_link.send_keys(:tab)
    
    # Check that tooltip appears
    expect(page).to have_selector('.tooltip', visible: true)
  end

  it "allows dismissing tooltip with Escape key", js: true do
    visit collection_read_work_path(@work.collection.owner, @work.collection, @work)
    page.find('.work-page_title', text: @title).click_link(@title)
    
    # Focus on subject link to show tooltip
    subject_link = page.find('a[data-controller="tooltip"]', text: 'Test Subject')
    subject_link.click
    
    # Verify tooltip is visible
    expect(page).to have_selector('.tooltip', visible: true)
    
    # Press Escape to dismiss
    page.send_keys(:escape)
    
    # Verify tooltip is hidden
    expect(page).not_to have_selector('.tooltip', visible: true)
  end

  it "keeps tooltip visible when hovering over it", js: true do
    visit collection_read_work_path(@work.collection.owner, @work.collection, @work)
    page.find('.work-page_title', text: @title).click_link(@title)
    
    # Hover over subject link
    subject_link = page.find('a[data-controller="tooltip"]', text: 'Test Subject')
    subject_link.hover
    
    # Verify tooltip appears
    expect(page).to have_selector('.tooltip', visible: true)
    
    # Move mouse to tooltip
    tooltip = page.find('.tooltip')
    tooltip.hover
    
    # Tooltip should remain visible
    expect(page).to have_selector('.tooltip', visible: true)
  end
end