require 'spec_helper'

describe "owner actions", :order => :defined do

  before :all do

    @user = User.find_by(login: 'minerva')
    @collections = @user.all_owner_collections
    @collection = @collections.first
    @works = @user.owner_works
  end

  it "imports a work from IA" do
    ia_work_count = IaWork.all.count
    works_count = @user.owner_works.count
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
    select 'FPS', from: 'collection_id'
    click_button('Publish Work')
    expect(page).to have_content("has been converted into a FromThePage work")
    expect(ia_work_count + 1).to eq IaWork.all.count
    expect(works_count + 1).to eq @user.owner_works.count
  end

  it "imports a work from IA and uses OCR" do
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
    select 'FPS', from: 'collection_id'
    click_button('Publish Work')
    new_work = Work.find_by(title: "[Letter to] Dear Garrison [manuscript]")
    first_page = new_work.pages.first
    expect(first_page.status).to eq 'raw_ocr'
    expect(page).to have_content("has been converted into a FromThePage work")
    expect(page.find('h1')).to have_content(new_work.title)
    expect(first_page.source_text).not_to be_nil
  end

end