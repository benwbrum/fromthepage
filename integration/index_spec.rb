require "spec_helper"

describe "index page" do
  before(:all) do
    # @book = FactoryGirl.create(:book)
    # @book2 = FactoryGirl.create(:book2)
  end


  it "should have a link to log in and sign up if not logged in" do
    visit "/"
    page.should_not have_content("Log out")
    page.should have_content("Log in")
    page.should have_content("Sign Up")
  end

  it "should have link to log out if logged in" do
    
    p = SessionProvider.get_session
    visit "/"
    page.should have_content("Log out")
    page.should_not have_content("Log in")
    page.should_not have_content("Sign Up")
    
  end


=begin
  it "gets a session from Provider " do

    user2 = FactoryGirl.create(:user2)

    fd = Deed.new 
    fd.note_id = 1
    fd.page_id = 1
    fd.work_id = 1
    fd.collection_id = 1
    fd.deed_type = Deed::PAGE_TRANSCRIPTION
    fd.user_id = user2.id
    fd.save!
=end
=begin
deedid: 1, deed_type: "page_trans", page_id: 632, work_id: 2, collection_id: 1, article_id: nil, user_id: 2, note_id: nil, created_at: "2008-03-10 12:42:23", updated_at: "2008-04-07 22:34:06"> 
1.9.3-p0 :002 > ld = Deed.last
  Deed Load (0.4ms)  SELECT `deeds`.* FROM `deeds` ORDER BY `deeds`.`id` DESC LIMIT 1
 => #<Deed id: 4948, deed_type: "page_edit", page_id: 2056, work_id: 16, collection_id: 1, article_id: nil, user_id: 221, note_id: nil, created_at: "2012-12-07 04:39:02", updated_at: "2012-12-07 04:39:02"> 
    deed = Deed.new
    deed.note = @note
    deed.page = @page
    deed.work = @work
    deed.collection = @collection
    deed.deed_type = Deed::NOTE_ADDED
    deed.user = current_user
    deed.save!
=end
################

=begin    
    p = SessionProvider.get_session
    visit "/dashboard/main_dashboard"
    page.should have_content("Log out")
  end
=end

end
