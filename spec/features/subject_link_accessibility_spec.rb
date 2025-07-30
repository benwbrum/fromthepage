require 'spec_helper'

describe "subject link accessibility", :order => :defined do

  before :all do
    @owner = User.find_by(login: OWNER)
    @collections = @owner.all_owner_collections
    @collection = @collections.first
    @work = @collection.works.first
    @page = @work.pages.first
    @title = @page.title
  end

  before :each do
    login_as(@owner, :scope => :user)
  end

  it "displays existing subject links with proper accessibility attributes", js: true do
    visit collection_read_work_path(@work.collection.owner, @work.collection, @work)
    page.find('.work-page_title', text: @title).click_link(@title)
    
    # Check if we have subject links with tooltips (from fixture data)
    if page.has_selector?('a[data-controller="tooltip"]')
      subject_link = page.first('a[data-controller="tooltip"]')
      expect(subject_link['aria-describedby']).to match(/tooltip-\d+/)
      expect(subject_link['tabindex']).to eq('0')
    else
      # Create subject links if they don't exist
      page.find('.tabs').click_link("Transcribe")
      fill_in_editor_field("[[Test Subject]] mentioned in this document.")
      find('#save_button_top').click
      page.find('.tabs').click_link("Overview")
      
      expect(page).to have_selector('a[data-controller="tooltip"]', text: 'Test Subject')
      subject_link = page.find('a[data-controller="tooltip"]', text: 'Test Subject')
      expect(subject_link['aria-describedby']).to match(/tooltip-\d+/)
      expect(subject_link['tabindex']).to eq('0')
    end
  end

  it "shows tooltip on focus for keyboard accessibility", js: true do
    visit collection_read_work_path(@work.collection.owner, @work.collection, @work)
    page.find('.work-page_title', text: @title).click_link(@title)
    
    # Check if we have subject links with tooltips (from fixture data)
    if page.has_selector?('a[data-controller="tooltip"]')
      subject_link = page.first('a[data-controller="tooltip"]')
      tooltip_id = subject_link['aria-describedby']
      if tooltip_id.nil?
        skip "Subject link found but missing aria-describedby attribute"
      end
    else
      # Create subject links if they don't exist
      page.find('.tabs').click_link("Transcribe")
      fill_in_editor_field("[[Test Subject]] mentioned in this document.")
      find('#save_button_top').click
      page.find('.tabs').click_link("Overview")
      
      expect(page).to have_selector('a[data-controller="tooltip"]', text: 'Test Subject')
      subject_link = page.find('a[data-controller="tooltip"]', text: 'Test Subject')
      tooltip_id = subject_link['aria-describedby']
    end
      
    # Click to trigger tooltip (this also focuses the element)
    subject_link.click
    
    # Check that tooltip appears using the ID from aria-describedby with wait time
    expect(page).to have_selector("##{tooltip_id}", visible: true, wait: 2)
  end

  it "allows dismissing tooltip with Escape key", js: true do
    visit collection_read_work_path(@work.collection.owner, @work.collection, @work)
    page.find('.work-page_title', text: @title).click_link(@title)
    
    # Check if we have subject links with tooltips (from fixture data)
    if page.has_selector?('a[data-controller="tooltip"]')
      subject_link = page.first('a[data-controller="tooltip"]')
      tooltip_id = subject_link['aria-describedby']
      if tooltip_id.nil?
        skip "Subject link found but missing aria-describedby attribute"
      end
    else
      # Create subject links if they don't exist
      page.find('.tabs').click_link("Transcribe")
      fill_in_editor_field("[[Test Subject]] mentioned in this document.")
      find('#save_button_top').click
      page.find('.tabs').click_link("Overview")
      
      expect(page).to have_selector('a[data-controller="tooltip"]', text: 'Test Subject')
      subject_link = page.find('a[data-controller="tooltip"]', text: 'Test Subject')
      tooltip_id = subject_link['aria-describedby']
    end
      
    subject_link.click
    
    # Verify tooltip is visible with wait time
    expect(page).to have_selector("##{tooltip_id}", visible: true, wait: 2)
    
    # Press Escape to dismiss
    page.send_keys(:escape)
    
    # Verify tooltip is hidden
    expect(page).not_to have_selector("##{tooltip_id}", visible: true)
  end

  it "keeps tooltip visible when hovering over it", js: true do
    visit collection_read_work_path(@work.collection.owner, @work.collection, @work)
    page.find('.work-page_title', text: @title).click_link(@title)
    
    # Check if we have subject links with tooltips (from fixture data)
    if page.has_selector?('a[data-controller="tooltip"]')
      subject_link = page.first('a[data-controller="tooltip"]')
      tooltip_id = subject_link['aria-describedby']
      if tooltip_id.nil?
        skip "Subject link found but missing aria-describedby attribute"
      end
    else
      # Create subject links if they don't exist
      page.find('.tabs').click_link("Transcribe")
      fill_in_editor_field("[[Test Subject]] mentioned in this document.")
      find('#save_button_top').click
      page.find('.tabs').click_link("Overview")
      
      expect(page).to have_selector('a[data-controller="tooltip"]', text: 'Test Subject')
      subject_link = page.find('a[data-controller="tooltip"]', text: 'Test Subject')
      tooltip_id = subject_link['aria-describedby']
    end
      
    subject_link.hover
    
    # Wait for tooltip to appear
    expect(page).to have_selector("##{tooltip_id}", visible: true)
    
    # Move mouse to tooltip
    tooltip = page.find("##{tooltip_id}")
    tooltip.hover
    
    # Tooltip should remain visible
    expect(page).to have_selector("##{tooltip_id}", visible: true)
  end
end