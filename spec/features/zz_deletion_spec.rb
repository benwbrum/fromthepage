
#Note - this test must fall at the very end of the features specs
require 'spec_helper'

describe "testing deletions" do

  before :all do
    @owner = User.find_by(login: 'margaret')
    @collections = @owner.all_owner_collections
    @collection = @collections.last
    @document_sets = DocumentSet.where(owner_user_id: @owner.id)
  end

  before :each do
    login_as(@owner, :scope => :user)
  end    

  it "blanks out the data in a collection" do
    #note, don't use last collection because it causes problems with later tests
    col = @collections.first
    visit collection_path(col.owner, col)
    page.find('.tabs').click_link("Settings")
    expect(page).to have_content("Blank Collection")
    page.find('a', text: 'Blank Collection').click
    expect(page.current_path).to eq("/collection/show")
    pages = Page.where(work_id: col.works.ids)
    pages.each do |p|
      expect(p.status).to be_nil
      expect(p.page_versions.first.page_version).to eq 0
    end
    expect(Deed.where(page_id: pages.ids)).to be_empty
  end

  it "deletes a document set" do
    count = @document_sets.count
    visit dashboard_owner_path
    page.find('.maincol').find('a', text: @collection.title).click
    page.find('.tabs').click_link("Sets")
    expect(page).to have_content("Document Sets for #{@collection.title}")
    within(page.find('#sets')) do
      within(page.find('tr', text: @document_sets.first.title)) do
        page.find('a', text: 'Delete').click
      end
    end
    sets = DocumentSet.all.count
    expect(sets).to eq (count - 1)
    expect(page).not_to have_content(@document_sets.first.title)
    expect(page).to have_content(@document_sets.last.title)
  end

  it "deletes a page" do
    work = @collection.works.first
    count = work.pages.count
    test_page = work.pages.first
    visit dashboard_owner_path
    page.find('.maincol').find('a', text: work.title).click
    expect(page).to have_content(work.title)
    page.find('.tabs').click_link("Read")
    expect(page).to have_content(test_page.title)
    page.find('.work-page_title', text: test_page.title).click_link(test_page.title)
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
    visit dashboard_owner_path
    page.find('.maincol').find('a', text: work.title).click
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
    visit dashboard_owner_path
    page.find('.collection_title', text: @collection.title).click_link(@collection.title)
    @collection.works.each do |w|
      expect(page).to have_content(w.title)
    end
    page.find('.tabs').click_link("Settings")
    expect(page).to have_selector('a', text: 'Delete Collection')
    page.find('a', text: 'Delete Collection').click
    del_count = @owner.all_owner_collections.count
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
