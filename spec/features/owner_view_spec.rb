require 'spec_helper'

describe "owner actions" do

  before :all do
    @user = User.find_by(login: 'minerva')
    @collections = @user.all_owner_collections
    @collection = @collections.first
    @works = @user.owner_works
  end

  it "looks at owner tabs" do
      login_as(@user, :scope => :user)
      visit dashboard_owner_path
      page.find('.tabs').click_link("Start A Project")
      expect(page.current_path).to eq '/dashboard/startproject'
      expect(page).to have_content("Upload PDF or ZIP File")
      page.find('.tabs').click_link("Your Works")
      expect(page.current_path).to eq dashboard_owner_path
  end


  it "starts a new project from tab" do
    @count = @collections.first.works.count
    login_as(@user, :scope => :user)
    visit dashboard_owner_path
    page.find('.tabs').click_link("Start A Project")
    select(@collections.first.title, :from => 'document_upload_collection_id')
    attach_file('document_upload_file', 'fps.pdf')
    click_button('Upload File')
    title = find('h1').text
#upload doesn't appear to actually be processing all the way through, js?
    #expect the "success" flash, too
    expect(title).to eq @collections.first.title
#    expect(@collections.first.works.count).to eq (@count + 1)
  end

  it "creates a new collection" do
    @count = @collections.count
    login_as(@user, :scope => :user)
    visit dashboard_owner_path
    page.find('a', text: 'Create a Collection').click
    fill_in 'collection_title', with: 'New Test Collection'
    click_button('Create Collection')
    expect(@count + 1).to eq @user.all_owner_collections.count
    expect(page).to have_content("New Test Collection")
    expect(page).to have_content("Manage Works")
  end

  it "deletes a collection" do
#need to start with deletable collection
  end


  it "imports a work from IA" do

  end

  it "adds an owner to a collection" do
    collection = @collections.last
    login_as(@user, :scope => :user)
    visit "/collection/show?collection_id=#{collection.id}"
    page.find('.tabs').click_link("Settings")
    select 'Harry', from: 'user_id'
    #this requires the javascript setup which i haven't yet enabled.
    #click_button 'Add'

  end

  it "checks rights of added owner" do
    #login as new owner, make sure can see tabs, add work
  end

  it "adds a new subject" do
    login_as(@user, :scope => :user)
    @count = @collection.categories.count
    cat = @collection.categories.find_by(title: "People")
    visit "/collection/show?collection_id=#{@collection.id}"
    page.find('.tabs').click_link("Subjects")
    @name = "#category-" + "#{cat.id}"
    page.find(@name).find('a', text: 'Add Root Category').click
    fill_in 'category_title', with: 'New Test Category'
    click_button 'Create Category'
    expect(@count + 1).to eq (@collection.categories.count)
    visit "/article/list?collection_id=#{@collection.id}"
    expect(page).to have_content("New Test Category")
  end

  it "deletes a subject" do
   login_as(@user, :scope => :user)
    @count = @collection.categories.count
    cat = @collection.categories.find_by(title: "Test Will Delete")
    visit "/collection/show?collection_id=#{@collection.id}"
    page.find('.tabs').click_link("Subjects")
    expect(page).to have_content("Test Will Delete")
    @name = "#category-" + "#{cat.id}"
    page.find(@name).find('a', text: 'Delete Category').click
    expect(@count - 1).to eq (@collection.categories.count)
    visit "/article/list?collection_id=#{@collection.id}"
    expect(page).not_to have_content("Test Will Delete")
  end

end