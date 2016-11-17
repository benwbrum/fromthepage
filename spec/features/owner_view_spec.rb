require 'spec_helper'

describe "owner actions", :order => :defined do

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

  it "looks at subjects tab" do
    login_as(@user, :scope => :user)
    visit "/collection/show?collection_id=#{@collection.id}"
    page.find('.tabs').click_link("Subjects")
    expect(page).to have_content("Categories")
    expect(page).to have_content("People")
    expect(page).to have_content("Places")
  end

  it "looks at statistics tab" do
    login_as(@user, :scope => :user)
    visit "/collection/show?collection_id=#{@collection.id}"
    page.find('.tabs').click_link("Statistics")
    expect(page).to have_content("Works")
    expect(page).to have_content("Work Progress")
    @collections.first.works.each do |w|
      expect(page).to have_content(w.title)
    end
    #need to test actual stats
  end

  it "looks at settings tab" do
    login_as(@user, :scope => :user)
    visit "/collection/show?collection_id=#{@collection.id}"
    page.find('.tabs').click_link("Settings")
    expect(page).to have_content(@collection.title)
    expect(page).to have_content("Manage Works")
    @collections.first.works.each do |w|
      expect(page).to have_content(w.title)
    end
  end

  it "looks at export tab" do
    login_as(@user, :scope => :user)
    visit "/collection/show?collection_id=#{@collection.id}"
    page.find('.tabs').click_link("Export")
    expect(page).to have_content(@collection.title)
    expect(page).to have_content("Export Subject Index")
    expect(page).to have_content("Export Individual Works")
    @collections.first.works.each do |w|
      expect(page).to have_content(w.title)
    end
  end

  it "looks at collaborators tab" do
    login_as(@user, :scope => :user)
    visit "/collection/show?collection_id=#{@collection.id}"
    page.find('.tabs').click_link("Collaborators")
    expect(page).to have_content(@collection.title)
    expect(page).to have_content("Contributions Between")
    expect(page).to have_content("All Collaborators")
  end

end