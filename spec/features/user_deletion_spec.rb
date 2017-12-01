require 'spec_helper'

describe "User deletion" do

  before :all do
    # create a user
    # do a lot of things as that user
     # transcribe a page
     # edit an article
    # delete the user
    @user = User.create(:login=>'foo', :password=> 'barbarbar', :password_confirmation=>'barbarbar', :email=>"foo@example.com")
    @collection = Collection.first
    @work = @collection.works.first
    @page1 = @work.pages.first

    # do a llot of things as that user
    login_as(@user, :scope => :user)
    visit collection_read_work_path(@work.collection.owner, @work.collection, @work)

    page.find('.work-page_title', text: @page1.title).click_link(@page1.title)
    # leave a note
    fill_in 'note_body', with: "Test private note"
    click_button('Submit')

     # transcribe a page
    visit "/display/display_page?page_id=#{@page1.id}"
    page.find('.tabs').click_link("Transcribe")
    page.fill_in 'page_source_text', with: "[[Places|Texas]]"
    click_button('Save Changes')

    @article = Article.first
    visit "/article/show?article_id=#{@article.id}"
    click_link("Settings")
    page.fill_in 'article_source_text', with: "This is more text about my article."
    click_button('Save Changes')

    @admin = User.where(:admin => true).first
    login_as(@admin, :scope => :user)
    visit url_for(:action => 'delete_user', :controller => 'admin', :user_id => @user.id)    
  end
  
  it "does not break collection home" do
     visit collection_path(@collection.owner, @collection)
  end
  
  it "does not break deed list" do
    visit url_for(:action => 'list', :controller => 'deed')        
  end
  
  it "does not break work versions" do
    visit collection_read_work_path(@work.collection.owner, @work.collection, @work)
    click_link("Versions")
  end

  it "does not break page versions" do
    visit "/display/display_page?page_id=#{@page1.id}"
    click_link("Versions")    
  end

  it "does not break page notes" do
    visit "/display/display_page?page_id=#{@page1.id}"    
  end

  it "does not break article versions" do
    visit "/article/show?article_id=#{@article.id}"
    click_link("Versions")
  end


end