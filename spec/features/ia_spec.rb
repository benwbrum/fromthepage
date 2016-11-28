require 'spec_helper'

describe "IA import actions", :order => :defined do

  before :all do

    @user = User.find_by(login: 'margaret')
    @collections = @user.all_owner_collections
    @collection = @collections.first
    @works = @user.owner_works
  end

  it "imports a work from IA" do
    ia_work_count = IaWork.all.count
    works_count = @works.count
    ia_link = "https://archive.org/details/lettertosamuelma00estl"
    login_as(@user, :scope => :user)
    visit dashboard_owner_path
    page.find('.tabs').click_link("Start A Project")
    click_link("Import From Archive.org")
    fill_in 'detail_url', with: ia_link
    click_button('Import Work')
    if page.has_button?('Import Anyway')
      click_button('Import Anyway')
    end
    expect(page).to have_content("Manage Archive.org Import")
    select @collection.title, from: 'collection_id'
    click_button('Publish Work')
    expect(page).to have_content("has been converted into a FromThePage work")
    expect(ia_work_count + 1).to eq IaWork.all.count
    expect(works_count + 1).to eq @user.owner_works.count
  end

  it "uses OCR when importing a work from IA" do
    ia_work_count = IaWork.all.count
    ia_link = "https://archive.org/details/lettertodeargarr00mays"
    login_as(@user, :scope => :user)
    visit dashboard_owner_path
    page.find('.tabs').click_link("Start A Project")
    click_link("Import From Archive.org")
    fill_in 'detail_url', with: ia_link
    click_button('Import Work')
    if page.has_button?('Import Anyway')
      click_button('Import Anyway')
    end
    expect(ia_work_count + 1).to eq IaWork.all.count
    expect(page).to have_content("Manage Archive.org Import")
    page.check('use_ocr')
    select @collection.title, from: 'collection_id'
    click_button('Publish Work')
    new_work = Work.find_by(title: "[Letter to] Dear Garrison [manuscript]")
    first_page = new_work.pages.first
    expect(first_page.status).to eq 'raw_ocr'
    expect(page).to have_content("has been converted into a FromThePage work")
    expect(page.find('h1')).to have_content(new_work.title)
    expect(first_page.source_text).not_to be_nil
  end

=begin
#this tests the new ocr-deeds code
  it "tests ocr correction" do
    @work = Work.find_by(title: "[Letter to] Dear Garrison [manuscript]")
    @page = @work.pages.first
    login_as(@user, :scope => :user)
    visit "/display/read_work?work_id=#{@work.id}"
    expect(page).to have_content("This page is not corrected, please help correct this page")
    click_link @page.title
    expect(page).to have_content("This page is not corrected")
    page.find('.tabs').click_link("Correct")
    expect(page.find('#page_status')).to have_content("Incomplete Correction")
    page.fill_in 'page_source_text', with: "Test OCR Correction"
    click_button('Save Changes')
    expect(page).to have_content("Test OCR Correction")
    expect(page).to have_content("Facsimile")
    expect(page.find('.tabs')).to have_content("Correct")
    @page = @work.pages.first
    expect(@page.status).to eq "part_ocr" 
  end
=end
end