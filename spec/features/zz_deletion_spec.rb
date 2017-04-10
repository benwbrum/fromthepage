#Note - this test must fall at the very end of the features specs
require 'spec_helper'

describe "testing deletions" do

  before :all do
    @user = User.find_by(login: 'margaret')
    @collections = @user.all_owner_collections
    @collection = @collections.last
  end

  it "deletes a page" do
    work = @collection.works.last
    count = work.pages.count
    test_page = work.pages.first
    login_as(@user, :scope => :user)
    visit dashboard_owner_path
    page.find('a', text: work.title).click
    expect(page).to have_content(work.title)
    page.find('.tabs').click_link("Read")
    expect(page).to have_content(test_page.title)
    page.find('.work-page', text: test_page.title).click_link(test_page.title)
    page.find('.tabs').click_link("Settings")
    page.find('a', text: 'Delete Page').click
    del_count = work.pages.count
    expect(del_count).to eq (count - 1)
    deeds = Deed.where(page_id: test_page.id)
    expect(deeds).to be_empty
    versions = test_page.page_versions
    expect(versions).to be_empty
  end

  it "deletes a work" do
    work = Work.find_by(title: 'test')
    work_count = Work.all.count
    page_count = work.pages.count
    expect(page_count).to be > 0
    id = work.id
    path = File.join(Rails.root, "public", "images", "uploaded", id.to_s)
    expect(Dir.exist?(path)).to be true
    login_as(@user, :scope => :user)
    visit dashboard_owner_path
    page.find('a', text: work.title).click
    expect(page).to have_content(work.title)
    expect(page).to have_selector('a', text: 'Delete Work')
    page.find('a', text: 'Delete Work').click
    #check that each child association has deleted
    del_work_count = Work.all.count
    expect(del_work_count).to eq (work_count - 1)
    pages = work.pages
    expect(pages).to be_empty
    deeds = Deed.where(work_id: work.id)
    expect(deeds).to be_empty
    expect(Dir.exist?(path)).to be false
  end

  it "deletes a collection" do
    count = @collections.count
    work_count = @collection.works.count
    expect(work_count).to be > 0
    article_count = @collection.articles.count
    expect(article_count).to be > 0
    doc_sets = @collection.document_sets.count
    expect(doc_sets).to be > 0
    login_as(@user, :scope => :user)
    visit dashboard_owner_path
    page.find('.collection_title', text: @collection.title).click_link(@collection.title)
    @collection.works.each do |w|
      expect(page).to have_content(w.title)
    end
    page.find('.tabs').click_link("Settings")
    expect(page).to have_selector('a', text: 'Delete Collection')
    page.find('a', text: 'Delete Collection').click
    del_count = @user.all_owner_collections.count
    expect(del_count).to eq (count - 1)
    #make sure child associations are also deleted
    works = Work.where(collection_id: @collection.id)
    expect(works).to be_empty
    articles = Article.where(collection_id: @collection.id)
    expect(articles).to be_empty
    doc_sets = DocumentSet.where(collection_id: @collection.id)
    expect(doc_sets).to be_empty

  end


end