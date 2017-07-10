require 'spec_helper'

describe "document sets", :order => :defined do

  before :all do

    @owner = User.find_by(login: 'margaret')
    @user = User.find_by(login: 'eleanor')
    @collections = @owner.all_owner_collections
    @collection = @collections.last
  end

  before :each do
    @document_sets = DocumentSet.where(owner_user_id: @owner.id)
    @set = DocumentSet.first
  end

  it "adds new document sets" do
    login_as(@owner, :scope => :user)
    visit dashboard_owner_path
    doc_set = DocumentSet.where(owner_user_id: @owner.id).count
    page.find('.maincol').find('a', text: @collection.title).click
    page.find('.tabs').click_link("Settings")
    page.find('.button', text: 'Create Document Sets').click
    expect(page).to have_content('Create a Document Set')
    page.find('.button', text: 'Create a Document Set').click
    page.fill_in 'document_set_title', with: "Test Document Set 1"
    page.find_button('Create Document Set').click
    expect(page).to have_content("Assign Works to Document Sets")
    expect(page).to have_content("Test Document Set 1")
    after_doc_set = DocumentSet.where(owner_user_id: @owner.id).count
    expect(after_doc_set).to eq (doc_set + 1)
    doc_set = DocumentSet.where(owner_user_id: @owner.id).count
    page.find('.button', text: 'Create a Document Set').click
    page.fill_in 'document_set_title', with: "Test Document Set 2"
    page.find_button('Create Document Set').click
    expect(page).to have_content("Test Document Set 2")
    after_doc_set = DocumentSet.where(owner_user_id: @owner.id).count
    expect(after_doc_set).to eq (doc_set + 1)
  end

  it "adds works to document sets" do
    login_as(@owner, :scope => :user)
    visit dashboard_owner_path
    page.find('.maincol').find('a', text: @collection.title).click
    page.find('.tabs').click_link("Sets")
    expect(page).to have_content("Document Sets for #{@collection.title}")
    page.check("work_assignment_#{@document_sets.first.id}_#{@collection.works.first.id}")
    page.check("work_assignment_#{@document_sets.first.id}_#{@collection.works.second.id}")
    page.check("work_assignment_#{@document_sets.last.id}_#{@collection.works.last.id}")
    page.find_button('Save').click
  end

  it "edits a document set (collection level)" do
    login_as(@owner, :scope => :user)
    visit dashboard_owner_path
    page.find('.maincol').find('a', text: @collection.title).click
    page.find('.tabs').click_link("Sets")
    expect(page).to have_content("Document Sets for #{@collection.title}")
    within(page.find('#sets')) do
      within(page.find('tr', text: @document_sets.first.title)) do
          page.find('a', text: 'Edit').click
      end
    end
    page.fill_in 'document_set_title', with: "Edited Test Document Set 1"
    page.check 'Public'
    page.find_button('Save Document Set').click
    expect(page).to have_content("Document Sets for #{@collection.title}")
    expect(page).to have_content(@document_sets.first.title)
    within(page.find('#sets')) do
      within(page.find('tr', text: @document_sets.first.title)) do
        expect(page).to have_content("Public")
      end
    end
  end

  it "views document sets" do
    #need to restrict collection and see what the user can see
    login_as(@owner, :scope => :user)
    visit dashboard_path
    @collections.each do |c|
      expect(page).to have_content(c.title)
    end
    @document_sets.each do |set|
      if set.is_public
        expect(page).to have_content(set.title)
      end
    end
    page.find('.maincol').find('a', text: @set.title).click
    expect(page).to have_content("Overview")
    expect(page).to have_content(@collection.works.first.id)
    expect(page).to have_content(@collection.works.second.id)
    expect(page).to have_content(@set.works.first.title)
    page.find('.tabs').click_link('Statistics')
    expect(page).to have_content(@set.title)
    expect(page.current_path).to eq "/#{@owner.slug}/#{@set.slug}/statistics"
    expect(page).to have_content("Last 7 Days Statistics")
  end

  it "looks at document sets owner tabs" do
    login_as(@owner, :scope => :user)
    work = @set.works.first
    visit "/#{@owner.slug}/#{@set.slug}"
    page.find('.tabs').click_link("Collaborators")
    expect(page.current_path).to eq "/#{@owner.slug}/#{@set.slug}/collaborators"
    expect(page).to have_content("Contributions Between")
    page.find('.tabs').click_link("Settings")
    expect(page.current_path).to eq "/#{@owner.slug}/#{@set.slug}/settings"
    expect(page.find('h1')).to have_content(@set.title)
    expect(page).to have_content("Title")
    expect(page).not_to have_content("Collection Owners")
    visit "/#{@owner.slug}/#{@set.slug}/#{work.slug}"
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @set.title)
    page.find('.tabs').click_link("Pages")
    expect(page.current_path).to eq "/#{@owner.slug}/#{@set.slug}/#{work.slug}/pages"
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @set.title)
    page.find('.tabs').click_link("Settings")
    expect(page.current_path).to eq "/#{@owner.slug}/#{@set.slug}/#{work.slug}/edit"
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @set.title)
    page.check('work_supports_translation')
    click_button('Save Changes')
    expect(page.current_path).to eq "/#{@owner.slug}/#{@set.slug}/#{work.slug}/edit"
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @set.title)
  end

  it "checks document set breadcrumbs - collection" do
    login_as(@user, :scope => :user)
    visit dashboard_path
    page.find('.maincol').find('a', text: @set.title).click
    expect(page.current_path).to eq "/#{@owner.slug}/#{@set.slug}"
    page.find('.tabs').click_link("Statistics")
    expect(page.current_path).to eq "/#{@owner.slug}/#{@set.slug}/statistics"
    expect(page.find('h1')).to have_content(@set.title)
    @set.works.each do |w|
      expect(page.find('.collection-work-stats')).to have_content(w.title)
    end
    page.find('.tabs').click_link("Subjects")
    expect(page.current_path).to eq "/#{@owner.slug}/#{@set.slug}/subjects"
    expect(page.find('h1')).to have_content(@set.title)
  end

  it "checks document set breadcrumbs - work" do
    login_as(@user, :scope => :user)
    work = @set.works.first
    @page = work.pages.first
    visit dashboard_path
    page.find('.maincol').find('a', text: @set.title).click
    click_link(work.title)
    expect(page.current_path).to eq "/#{@owner.slug}/#{@set.slug}/#{work.slug}"
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @set.title)
    click_button('Pages That Need Review')
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @set.title)
    expect(page).to have_content("No pages found")
    click_button("View All Pages")
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @set.title)
    click_button('Translations That Need Review')
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @set.title)
    expect(page).to have_content("No pages found")
    click_button("View All Pages")
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @set.title)
    page.find('.tabs').click_link("About")
    expect(page.current_path).to eq "/#{@owner.slug}/#{@set.slug}/#{work.slug}/about"
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @set.title)
    page.find('.tabs').click_link("Contents")
    expect(page.current_path).to eq "/#{@owner.slug}/#{@set.slug}/#{work.slug}/contents"
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @set.title)
    page.find('.tabs').click_link("Versions")
    expect(page.current_path).to eq "/#{@owner.slug}/#{@set.slug}/#{work.slug}/versions"
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @set.title)
    page.find('.tabs').click_link("Help")
    expect(page.current_path).to eq "/#{@owner.slug}/#{@set.slug}/#{work.slug}/help"
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @set.title)
    click_link @set.title
    expect(page.current_path).to eq "/#{@owner.slug}/#{@set.slug}"
  end

  it "checks document set breadcrumbs - page level" do
    login_as(@user, :scope => :user)
    work = @set.works.first
    @page = work.pages.first
    #make sure it's right if you click on the page from the work
    visit "/#{@owner.slug}/#{@set.slug}/#{work.slug}"
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @set.title)
    click_link(@page.title)
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @set.title)
    expect(page.find('.breadcrumbs')).to have_selector('a', text: work.title)
    #so that it doesn't matter if the page has been transcribed, go directly to overview
    visit "/#{@owner.slug}/#{@set.slug}/#{work.slug}/display/#{@page.id}"
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @set.title)
    expect(page.find('.breadcrumbs')).to have_selector('a', text: work.title)
    page.find('.tabs').click_link("Transcribe")
    expect(page.current_path).to eq "/#{@owner.slug}/#{@set.slug}/#{work.slug}/transcribe/#{@page.id}"
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @set.title)
    expect(page.find('.breadcrumbs')).to have_selector('a', text: work.title)
    page.fill_in 'page_source_text', with: "Document set breadcrumbs"
    click_button('Save Changes')
    expect(page.current_path).to eq "/#{@owner.slug}/#{@set.slug}/#{work.slug}/display/#{@page.id}"
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @set.title)
    expect(page.find('.breadcrumbs')).to have_selector('a', text: work.title)
    expect(page).to have_content("Transcription")
    page.find('.tabs').click_link("Translate")
    expect(page.current_path).to eq "/#{@owner.slug}/#{@set.slug}/#{work.slug}/translate/#{@page.id}"
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @set.title)
    expect(page.find('.breadcrumbs')).to have_selector('a', text: work.title)
    page.fill_in 'page_source_translation', with: "Document set breadcrumbs - translation"
    click_button('Save Changes')
    expect(page.current_path).to eq "/#{@owner.slug}/#{@set.slug}/#{work.slug}/display/#{@page.id}"
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @set.title)
    expect(page.find('.breadcrumbs')).to have_selector('a', text: work.title)
    expect(page).to have_content("Translation")
    page.find('.tabs').click_link("Versions")
    expect(page.current_path).to eq "/#{@owner.slug}/#{@set.slug}/#{work.slug}/versions/#{@page.id}"
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @set.title)
    expect(page.find('.breadcrumbs')).to have_selector('a', text: work.title)
    click_link(work.title)
    expect(page.current_path).to eq "/#{@owner.slug}/#{@set.slug}/#{work.slug}"
    click_link @set.title
    expect(page.current_path).to eq "/#{@owner.slug}/#{@set.slug}"
  end

  it "edits a document set (document set level)" do
    login_as(@owner, :scope => :user)
    visit "/#{@owner.slug}/#{@set.slug}"
    page.find('.tabs').click_link("Settings")
    expect(page).to have_content("Title")
    page.fill_in 'document_set_slug', with: "#{@set.slug}-new"
    click_button('Save Document Set')
    expect(DocumentSet.first.slug).to eq "#{@set.slug}-new"
  end

end