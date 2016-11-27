require 'spec_helper'

describe "owner actions", :order => :defined do

  before :all do

    @user = User.find_by(login: 'margaret')
    @collections = @user.all_owner_collections
    @collection = @collections.first
    @works = @user.owner_works
  end

  it "starts a new project from tab" do
    login_as(@user, :scope => :user)
    visit dashboard_owner_path
    page.find('.tabs').click_link("Start A Project")
    select(@collections.first.title, :from => 'document_upload_collection_id')
    attach_file('document_upload_file', './test_data/uploads/test.pdf')
    click_button('Upload File')
    title = find('h1').text
    expect(title).to eq @collections.first.title
    expect(page).to have_content("Document has been uploaded")
    #Note - the check that the document is actually uploaded is in a 
    #separate test due to the way the rake task runs
  end

  it "creates a new collection" do
    collection_count = @user.all_owner_collections.count
    login_as(@user, :scope => :user)
    visit dashboard_owner_path
    page.find('a', text: 'Create a Collection').click
    fill_in 'collection_title', with: 'New Test Collection'
    click_button('Create Collection')
    test_collection = Collection.find_by(title: 'New Test Collection')
    expect(collection_count + 1).to eq @user.all_owner_collections.count
    expect(page).to have_content("#{test_collection.title}")
    expect(page).to have_content("Manage Works")
  end

  it "deletes a collection" do
    test_collection = Collection.find_by(title: 'New Test Collection')
    collection_count = @user.all_owner_collections.count
    login_as(@user, :scope => :user)
    visit dashboard_owner_path
    expect(page).to have_content("#{test_collection.title}")
    click_link("#{test_collection.title}")
    page.find('.tabs').click_link("Settings")
    click_link('Delete Collection')
    expect(page.current_path).to eq dashboard_owner_path
    expect(page).not_to have_content("#{test_collection.title}")
    expect(collection_count - 1).to eq @user.all_owner_collections.count

  end

  it "creates a subject" do
    login_as(@user, :scope => :user)
    @count = @collection.categories.count
    cat = @collection.categories.find_by(title: "People")
    visit "/collection/show?collection_id=#{@collection.id}"
    page.find('.tabs').click_link("Subjects")
    @name = "#category-" + "#{cat.id}"
    page.find(@name).find('a', text: 'Add Root Category').click
    fill_in 'category_title', with: 'New Test Category'
    click_button('Create Category')
    expect(@count + 1).to eq (@collection.categories.count)
    visit "/article/list?collection_id=#{@collection.id}"
    expect(page).to have_content("New Test Category")
  end

  it "deletes a subject" do
   login_as(@user, :scope => :user)
    @count = @collection.categories.count
    cat = @collection.categories.find_by(title: "New Test Category")
    visit "/collection/show?collection_id=#{@collection.id}"
    page.find('.tabs').click_link("Subjects")
    expect(page).to have_content("New Test Category")
    @name = "#category-" + "#{cat.id}"
    page.find(@name).find('a', text: 'Delete Category').click
    expect(@count - 1).to eq (@collection.categories.count)
    visit "/article/list?collection_id=#{@collection.id}"
    expect(page).not_to have_content("New Test Category")
  end

end