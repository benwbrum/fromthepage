require 'spec_helper'

describe "needs review", :order => :defined do

  before :all do
    @user = User.find_by(login: 'eleanor')
    @collections = Collection.all
    @collection = @collections.second
    @work = @collection.works.first
    @page = @work.pages.first
    @page2 = @work.pages.second
    @page3 = @work.pages.third
    @page4 = @work.pages.fourth
  end

  before :each do
    login_as(@user, :scope => :user)
  end

  it "marks pages as needing review" do
    visit "/collection/show?collection_id=#{@collection.id}"
    count = Page.where(status: 'review').count
    expect(page).to have_content(@collection.title)
    click_link @work.title
    page.find('.work-page_title', text: @page.title).click_link(@page.title)
    page.find('.tabs').click_link("Transcribe")
    page.fill_in 'page_source_text', with: "Review Text"
    page.check('page_needs_review')
    click_button('Save Changes')
    expect(page).to have_content("Review Text")
    expect(page).to have_content("Transcription")
    count2 = Page.where(status: 'review').count
    expect(count2).to eq (count + 1)
    expect(Page.find_by(id: @page.id).status).to eq ('review')
    page.find('.page-nav_next').click
    expect(page).to have_content(@page2.title)
    page.find('.tabs').click_link("Transcribe")
    page.fill_in 'page_source_text', with: "Review Text 2"
    page.check('page_needs_review')
    click_button('Save Changes')
    expect(page).to have_content("Review Text 2")
    expect(page).to have_content("Transcription")
    count3 = Page.where(status: 'review').count
    expect(count3).to eq (count2 + 1)
    expect(Page.find_by(id: @page2.id).status).to eq ('review')

  end

  it "filters list of review pages" do
    visit "/display/read_work?work_id=#{@work.id}"
    expect(page).to have_content(@work.title)
    pages = @work.pages.limit(5)
    pages.each do |p|
      expect(page.find('.maincol')).to have_content(p.title)
    end
    #look at review list
    click_button('Pages That Need Review')
    expect(page.find('.maincol')).to have_content(@page.title)
    expect(page.find('.maincol')).to have_content(@page2.title)
    expect(page.find('.maincol')).not_to have_content(@page3.title)
    expect(page.find('.maincol')).not_to have_content(@page4.title)
    #expect(page.find('.maincol')).not_to have_content(@work.pages.fifth.title)
    expect(page).to have_button('View All Pages')
    
    #return to original list
    click_button('View All Pages')
    pages = @work.pages.limit(5)
    pages.each do |p|
      expect(page.find('.maincol')).to have_content(p.title)
    end
    expect(page).to have_button('Pages That Need Review')
  end

  it "marks pages blank" do
    count = Page.where(status: 'blank').count
    visit "/display/read_work?work_id=#{@work.id}"
    expect(page).to have_content(@work.title)
    page.find('.work-page_title', text: @page3.title).click_link(@page3.title)
    expect(page).to have_content("This page is not transcribed")
    page.find('a', text: 'mark the page blank').click
    expect(page).to have_content("This page is blank")
    expect(Page.where(status: 'blank').count).to eq (count + 1)
    expect(Page.find_by(id: @page3.id).status).to eq ('blank')
    page.find('.page-nav_next').click
    expect(page).to have_content(@page4.title)
    expect(page).to have_content("This page is not transcribed")
    page.find('.tabs').click_link("Transcribe")
    page.check('mark_blank')
    click_button('Save Changes')
    expect(page).to have_content("This page is blank")
    expect(Page.where(status: 'blank').count).to eq (count + 2)
    expect(Page.find_by(id: @page4.id).status).to eq ('blank')

  
  end

  it "checks the wording on blank pages" do

  end

  it "marks translated pages as needing review" do
  end

  it "marks translated pages as blank" do
  end

  it "checks collection overview stats" do

  end

  it "checks collection statistics" do

  end

  it "marks pages as no longer needing review" do
  end

  it "marks pages not blank" do
  end

#might need to add test to archive_import_spec re correction wording

end
