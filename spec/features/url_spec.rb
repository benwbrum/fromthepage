require 'spec_helper'

describe "URL tests" do

  before :all do
    @owner = User.find_by(login: OWNER)
    @user = User.find_by(login: USER)
    @collection = Collection.joins(:deeds).where(deeds: {user_id: @user.id}).first
    @work = @collection.works.first
    @page = @work.pages.first
  end

  it "visits old URLs" do
    #check old paths for backwards compatibility
    visit "/collection/show?collection_id=#{@collection.id}"
    expect(page).to have_selector('h1', text: @collection.title)
    @collection.works.each do |w|
      expect(page).to have_content w.title
    end
    visit "/display/read_work?work_id=#{@work.id}"
    expect(page).to have_selector('a', text: @collection.title)
    expect(page).to have_selector('h1', text: @work.title)
  end

  it "checks URLs paths/breadcrumbs" do
    login_as(@user, :scope => :user)
    visit dashboard_watchlist_path
    page.find('h4', text: @collection.title).click_link(@collection.title)
    expect(page.current_path).to eq "/#{@owner.slug}/#{@collection.slug}"
    page.find('.collection-work_title', text: @work.title).click_link
    expect(page.current_path).to eq "/#{@owner.slug}/#{@collection.slug}/#{@work.slug}"
    #check breadcrumb
    expect(page).to have_selector('a', text: @collection.title)
    page.find('a', text: @page.title).click
    expect(page).to have_selector('a', text: @collection.title)
    expect(page).to have_selector('a', text: @work.title)
    click_link(@work.title)
    expect(page.current_path).to eq "/#{@owner.slug}/#{@collection.slug}/#{@work.slug}"
    click_link @collection.title
    expect(page.current_path).to eq "/#{@owner.slug}/#{@collection.slug}"
  end

  it "checks user URLs" do
    login_as(@user, :scope => :user)
    #look at the owner profile
    visit "/#{@owner.slug}"
    expect(page).to have_content("Collections")
    @owner.all_owner_collections.each do |c|
      expect(page).to have_content(c.title)
    end
    expect(page).not_to have_content("Recent Activity by #{@owner.display_name}")
    #look at a user profile
    visit "/#{@user.slug}"
    expect(page).to have_content(@user.display_name)
    expect(page).to have_content("Recent Activity by #{@user.display_name}")
    #make sure links go to user profile
    visit dashboard_watchlist_path
    click_link(@owner.display_name, match: :first)
    expect(page.current_path).to eq "/#{@owner.slug}"
    expect(page).to have_content("Collections")
    @owner.all_owner_collections.each do |c|
      expect(page).to have_content(c.title)
    end
  end

  it "edits a collection slug" do
    login_as(@owner, :scope => :user)
    #make sure path works correctly
    slug = "new-#{@collection.slug}"
    visit "/#{@owner.slug}/#{@collection.slug}"
    expect(page).to have_selector('h1', text: @collection.title)
    @collection.works.each do |w|
      expect(page).to have_content w.title
    end
    #edit the slug
    page.find('.tabs').click_link("Settings")
    expect(page).to have_field('collection[slug]', with: @collection.slug)
    page.fill_in 'collection_slug', with: "new-#{@collection.slug}"
    click_button('Save Changes')
    expect(page).to have_selector('h1', text: @collection.title)
    expect(page).to have_content("Title")
    expect(Collection.find_by(id: @collection.id).slug).to eq "#{slug}"
    #test new path
    visit "/#{@owner.slug}/#{slug}"
    expect(page).to have_selector('h1', text: @collection.title)
    @collection.works.each do |w|
      expect(page).to have_content w.title
    end
    #test old path
    #this variable is stored at the beginning of the test, so it's the original
    visit dashboard_owner_path
    visit "/#{@owner.slug}/#{@collection.slug}"
    expect(page).to have_selector('h1', text: @collection.title)
    @collection.works.each do |w|
      expect(page).to have_content w.title
    end
    #blank out the slug and make sure the original is there
    visit "/#{@owner.slug}/#{@collection.slug}"
    page.find('.tabs').click_link("Settings")
    page.fill_in 'collection_slug', with: ""
    click_button('Save Changes')
    expect(page).to have_selector('h1', text: @collection.title)
    expect(Collection.find_by(id: @collection.id).slug).to eq @collection.slug
  end

  it "edits a work slug" do
    login_as(@owner, :scope => :user)
    slug = "new-#{@work.slug}"
    #check that path works
    visit "/#{@owner.slug}/#{@collection.slug}/#{@work.slug}"
    expect(page).to have_selector('a', text: @collection.title)
    expect(page).to have_selector('h1', text: @work.title)
    #edit slug
    page.find('.tabs').click_link("Settings")
    expect(page).to have_field('work[slug]', with: @work.slug)
    page.fill_in 'work_slug', with: "new-#{@work.slug}"
    click_button('Save Changes')
    expect(page).to have_selector('h1', text: @work.title)
    expect(page).to have_content("Work title")
    expect(Work.find_by(id: @work.id).slug).to eq "#{slug}"
    #test new path
    visit "/#{@owner.slug}/#{@collection.slug}/#{slug}"
    expect(page).to have_selector('a', text: @collection.title)
    expect(page).to have_selector('h1', text: @work.title)
    #test old path
    #this variable is stored at the beginning of the test, so it's the original
    visit dashboard_owner_path
    visit "/#{@owner.slug}/#{@collection.slug}/#{@work.slug}"
    expect(page).to have_selector('a', text: @collection.title)
    expect(page).to have_selector('h1', text: @work.title)
    #blank out work slug
    visit "/#{@owner.slug}/#{@collection.slug}/#{@work.slug}"
    expect(page).to have_selector('a', text: @collection.title)
    page.find('.tabs').click_link("Settings")
    page.fill_in 'work_slug', with: ""
    click_button('Save Changes')
    expect(Work.find_by(id: @work.id).slug).to eq @work.slug
  end

  it "edits a user slug" do
    login_as(@owner, :scope => :user)
    visit dashboard_watchlist_path
    slug = "new-#{@owner.slug}"
    page.find('a', text: 'Your Profile').click
    #check original path
    expect(page.current_path).to eq "/#{@owner.slug}"
    expect(page).to have_content(@owner.display_name)
    expect(page).to have_content("User since #{@owner.created_at.strftime("%b %d, %Y")}")
    page.find('a', text: 'Edit Profile').click
    expect(page).to have_content("Update User Profile")
    expect(page).to have_field('user[slug]', with: @owner.slug)
    page.fill_in 'user_slug', with: "new-#{@owner.slug}"
    click_button('Update Profile')
    expect(page).to have_content(@owner.display_name)
    expect(page).to have_content("User since #{@owner.created_at.strftime("%b %d, %Y")}")
    expect(User.find_by(id: @owner.id).slug).to eq ("#{slug}")
    #test new path
    visit "/#{slug}"
    expect(page).to have_content(@owner.display_name)
    expect(page).to have_content("User since #{@owner.created_at.strftime("%b %d, %Y")}")
    #test old path
    #this variable is stored at the beginning of the test, so it's the original
    visit dashboard_path
    visit "/#{@user.slug}"
    expect(page).to have_content(@user.display_name)
    expect(page).to have_content("User since #{@owner.created_at.strftime("%b %d, %Y")}")
    #blank out user slug
    visit dashboard_watchlist_path
    page.find('a', text: 'Your Profile').click
    page.find('a', text: 'Edit Profile').click
    expect(page).to have_content("Update User Profile")
    page.fill_in 'user_slug', with: ""
    click_button('Update Profile')
    expect(User.find_by(id: @owner.id).slug).to eq @owner.slug
  end

end