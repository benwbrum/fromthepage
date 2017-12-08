require 'spec_helper'

describe "document sets", :order => :defined do

  before :all do
    @owner = User.find_by(login: OWNER)
    @user = User.find_by(login: USER)
    @collections = @owner.all_owner_collections
    @collection = @collections.last
  end

  before :each do
    @document_sets = DocumentSet.where(owner_user_id: @owner.id)
    @set = DocumentSet.first
  end

  it "edits a document set (start at collection level)" do
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
    page.find_button('Save Document Set').click
    expect(DocumentSet.find_by(id: @document_sets.first.id).title).to eq "Edited Test Document Set 1"
    expect(page.find('h1')).to have_content(@document_sets.first.title)
  end

  it "makes a document set private" do
    login_as(@owner, :scope => :user)
    #create an additional document set to make private
    visit document_sets_path(:collection_id => @collection)
    page.find('.button', text: 'Create a Document Set').click
    page.fill_in 'document_set_title', with: "Test Document Set 3"
    page.find_button('Create Document Set').click
    expect(page.current_path).to eq collection_settings_path(@owner, DocumentSet.last)
    expect(page.find('h1')).to have_content("Test Document Set 3")
    expect(DocumentSet.last.is_public).to be true
    expect(page).not_to have_content("Document Set Collaborators")
    #make the set private
    page.find('.button', text: 'Make Document Set Private').click
    expect(DocumentSet.last.is_public).to be false
    expect(page).to have_content("Document Set Collaborators")
    #manually assign works until have the jqery test set
    id = @collection.works.third.id
    DocumentSet.last.work_ids = id
    DocumentSet.last.save!
    expect(DocumentSet.last.work_ids).to include @collection.works.third.id
  end

  it "views document sets - regular user" do
    #need to restrict collection to test user view
    @collection.restricted = true
    @collection.save!
    #user with no privileges first
    @test_set = DocumentSet.last
    login_as(@user, :scope => :user)
    visit dashboard_path
    @collections.each do |c|
      unless c.restricted
        expect(page).to have_content(c.title)
      else
        expect(page).not_to have_content(c.title)
      end
    end
    @document_sets.each do |set|
      if set.is_public
        expect(page).to have_content(set.title)
      elsif !set.is_public
        expect(page).not_to have_content(set.title)
      end
    end
    #check to view public document set
    page.find('.maincol').find('a', text: @set.title).click
    expect(page).to have_content("Overview")
    expect(page).to have_content(@collection.works.first.title)
    expect(page).to have_content(@collection.works.second.title)
    expect(page).not_to have_content(@collection.works.last.title)
    expect(page).to have_content(@set.works.first.title)
    page.find('.tabs').click_link('Statistics')
    expect(page).to have_content(@set.title)
    expect(page.current_path).to eq "/#{@owner.slug}/#{@set.slug}/statistics"
    expect(page).to have_content("Last 7 Days Statistics")
    page.find('.tabs').click_link('Overview')
    page.find('.collection-work_title', text: @set.works.first.title).click_link
    expect(page).to have_content(@set.works.first.title)
    page.find('.work-page_title').click_link(@set.works.first.pages.first.title)
    expect(page.current_path).not_to eq dashboard_path
    expect(page.find('h1')).to have_content(@set.works.first.pages.first.title)
    #can a restricted user access a private doc set through a link
    visit collection_path(@owner, @test_set)
    expect(page.current_path).to eq dashboard_path
    expect(page.find('h1')).not_to have_content(@test_set.title)
    #can a restricted user see a work from a private collection through a link
    visit collection_read_work_path(@owner, @collection, @collection.works.last)
    expect(page.current_path).to eq dashboard_path
    expect(page.find('h1')).not_to have_content(@collection.works.last.title)
  end

  it "adds a collaborator" do
    @test_set = DocumentSet.last
    #hack because of select 2 dropdown box
    @test_set.collaborators << @user
  end

  it "tests a collaborator" do
    @test_set = DocumentSet.last
    login_as(@user, :scope => :user)
    visit dashboard_path
    @collections.each do |c|
      unless c.restricted
        expect(page).to have_content(c.title)
      else
        expect(page).not_to have_content(c.title)
      end
    end
    @document_sets.each do |set|
      if set.is_public
        expect(page).to have_content(set.title)
      elsif !set.is_public
        if set.collaborators.include?(@user)
          expect(page).to have_content(set.title)
        else
          expect(page).not_to have_content(set.title)
        end
      end
    end
    #check collaborator access to private doc set
    visit collection_path(@owner, @test_set)
    expect(page.find('h1')).to have_content(@test_set.title)
    expect(page.find('.maincol')).to have_content(@test_set.works.first.title)
    #check collaborator access through a link
    visit collection_read_work_path(@owner, @test_set, @test_set.works.first)
    expect(page.find('h1')).to have_content(@test_set.works.first.title)
    #check that the collaborator can't access other private doc set
    visit collection_read_work_path(@owner, DocumentSet.second, DocumentSet.second.works.first)
    expect(page.current_path).to eq dashboard_path
    expect(page.find('h1')).not_to have_content(DocumentSet.second.works.first.title)
  end

  it "checks notes on a public doc set/private collection" do
    login_as(@user)
    visit collection_transcribe_page_path(@set.owner, @set, @set.works.first, @set.works.first.pages.first)
    fill_in 'note_body', with: "Test private note"
    click_button('Submit')
    expect(page).to have_content "Note has been created"
    note = Note.last
    visit collection_path(@set.owner, @set)
    page.find('a', text: "Test private note").click
    expect(page.current_path).to eq collection_display_page_path(@set.owner, @set, @set.works.first, @set.works.first.pages.first)
    page.find('.user-bubble_content', text: "Test private note")
    end

  it "cleans up test data" do
    @test_set = DocumentSet.last
    @collection.restricted = false
    @collection.save!
    #delete the new document set
    login_as(@owner, :scope => :user)
    visit document_sets_path(:collection_id => @collection)
    within(page.find('#sets')) do
      within(page.find('tr', text: @test_set.title)) do
          page.find('a', text: 'Delete').click
      end
    end
    expect(DocumentSet.all.ids).not_to include @test_set.id
    #delete the note in case of conflicts
#    Note.find_by(body: "Test private note").delete
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
  end

  it "checks document set breadcrumbs - subjects" do
    login_as(@user, :scope => :user)
    @article = @set.articles.first
    visit dashboard_path
    page.find('.maincol').find('a', text: @set.title).click
    page.find('.tabs').click_link("Subjects")
    expect(page.find('.category-tree')).to have_content(@set.categories.first.title)
    expect(page.current_path).to eq "/#{@owner.slug}/#{@set.slug}/subjects"
    expect(page.find('h1')).to have_content(@set.title)
    #expect to have only article from document sets
    expect(page).to have_selector('.category-article', text: @article.title)
    expect(page).not_to have_selector('.category-article', text: @collection.articles.last.title)
    page.find('a', text: @article.title).click
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @set.title)
    page.find('.tabs').click_link("Settings")
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @set.title)
    click_button 'Autolink'
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @set.title)
    click_button 'Save Changes'
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @set.title)
    page.find('.tabs').click_link("Versions")
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @set.title)
  end

  it "checks document set subject tabs" do
    login_as(@owner, :scope => :user)
    @article = @set.articles.first
    visit collection_article_show_path(@set.owner, @set, @article.id)
    expect(page).to have_content("Description")
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @set.title)
    page.find('a', text: 'Edit the description in the settings tab.').click
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @set.title)
    expect(page).to have_content("Title")
    page.find('.tabs').click_link("Overview")
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @set.title)
    expect(page.find('.sidecol')).to have_content(@article.categories.first.title)
    click_link("All references to #{@article.title}")
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @set.title)
    expect(page).to have_content("Search for")
    #return to overview
    visit collection_article_show_path(@set.owner, @set, @article.id)
    click_link("All references to #{@article.title} in pages that do not link to this subject")
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @set.title)
    expect(page).to have_content("Search for")
    page.find('a', text: "Show pages that mention #{@article.title} in all works").click
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @set.title)
    set_pages = @article.pages.where(work_id: @set.works.ids)
    col_pages = @article.pages.where.not(work_id: @set.works.ids)
    set_pages.each do |p|
      expect(page.find('.maincol')).to have_content(p.work.title)
      expect(page.find('.maincol')).to have_content(p.title)
    end
    col_pages.each do |p|
      expect(page.find('.maincol')).not_to have_content(p.work.title)
      expect(page.find('.maincol')).not_to have_content(p.title)
    end
    visit collection_article_show_path(@set.owner, @set, @article.id)
    page.find('.article-links').find('a', text: set_pages.first.title).click
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @set.title)
    if expect(page).to have_content("This page is not transcribed")
      page.find('.tabs').click_link("Transcribe")
      click_button('Save Changes')
      page.click_link("Overview")
    end
    page.find('a', text: @article.title).click
    expect(page.current_path).to eq collection_article_show_path(@set.owner, @set, @article.id)
    expect(page.find('.breadcrumbs')).to have_selector('a', text: @set.title)
  end

  it "checks document set breadcrumbs - work" do
    login_as(@user, :scope => :user)
    work = @set.works.first
    @page = work.pages.first
    visit dashboard_path
    page.find('.maincol').find('a', text: @set.title).click
    page.find('.collection-work_title', text: work.title).click_link
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
    page.find('.work-page_title', text: @page.title).click_link
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
    page.click_link("Overview")
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
    page.click_link("Overview")
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

  it "disables document sets" do
    login_as(@owner, :scope => :user)
    visit edit_collection_path(@collection.owner, @collection)
    page.find('.button', text: 'Disable Document Sets').click
    expect(Collection.find_by(id: @collection.id).supports_document_sets).to be false
  end

  it "enables document sets" do
    login_as(@owner, :scope => :user)
    visit edit_collection_path(@collection.owner, @collection)
    page.find('.button', text: 'Enable Document Sets').click
    expect(page.current_path).to eq document_sets_path
    @collection = @collections.last
    expect(@collection.supports_document_sets).to be true
  end

  it "edits a document set slug" do
    login_as(@owner, :scope => :user)
    slug = "new-#{@set.slug}"
    visit "/#{@owner.slug}/#{@set.slug}"
    expect(page).to have_selector('h1', text: @set.title)
    @set.works.each do |w|
      expect(page).to have_content w.title
    end
    page.find('.tabs').click_link('Settings')
    expect(page.find('h1')).to have_content @set.title
    expect(page).to have_field('document_set[slug]', with: @set.slug)
    page.fill_in 'document_set_slug', with: "new-#{@set.slug}"
    page.find_button('Save Document Set').click
    expect(page.find('h1')).to have_content @set.title
    expect(DocumentSet.find_by(id: @set.id).slug).to eq "#{slug}"
    #check new path
    visit "/#{@owner.slug}/#{slug}"
    expect(page).to have_selector('h1', text: @set.title)
    @set.works.each do |w|
      expect(page).to have_content w.title
    end
    #check the old path 
    #(this variable is stored at the beginning of the test, so it's the original)
    visit "/#{@owner.slug}/#{@set.slug}"
    expect(page).to have_selector('h1', text: @set.title)
    @set.works.each do |w|
      expect(page).to have_content w.title
    end
    #blank out doc set slug
    visit "/#{@owner.slug}/#{@set.slug}"
    expect(page).to have_selector('h1', text: @set.title)
    page.find('.tabs').click_link('Settings')
    expect(page.find('h1')).to have_content @set.title
    new_slug = DocumentSet.first.slug
    expect(page).to have_field('document_set[slug]', with: new_slug)
    page.fill_in 'document_set_slug', with: ""
    page.find_button('Save Document Set').click
    docset = DocumentSet.find_by(id: @set.id)
    #note - the document set title was changed so the slug is slightly different
    expect(docset.slug).to eq docset.title.parameterize
  end

end
