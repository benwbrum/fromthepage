require 'spec_helper'

describe "subject linking" do

  before :all do
    @user = User.find_by(login: 'eleanor')
    collection_ids = Deed.where(user_id: @user.id).distinct.pluck(:collection_id)
    @collections = Collection.where(id: collection_ids)
    @collection = @collections.first
    @work = @collection.works.first
  end

  #it checks to make sure the subject is on the page
  it "looks at subjects in a collection" do
    login_as(@user, :scope => :user)
    visit "/collection/show?collection_id=#{@collection.id}"
    page.find('.tabs').click_link("Subjects")
    expect(page).to have_content("Categories")
    categories = Category.where(collection_id: @collection.id)
    categories.each do |c|
      column = page.find('div.category-tree')
      expect(column).to have_content(c.title)
      column.click_link c.title
      c.articles.each do |a|
        expect(page).to have_content(a.title)
      end
    end
  end

  it "links a categorized subject" do
    login_as(@user, :scope => :user)
    @page = @work.pages.last
    visit "/display/display_page?page_id=#{@page.id}"
    page.find('.tabs').click_link("Transcribe")
    expect(page).to have_content("Status")
    page.fill_in 'page_source_text', with: "[[Places|Texas]]"
    click_button('Save Changes')
    expect(page).to have_content("Texas")
    page.find('a', text: 'Texas').click
    expect(page).to have_content("Related Subjects")
    expect(page).to have_content("Texas")
  end

  it "enters a bad link - no closing braces" do
    login_as(@user, :scope => :user)
    test_page = @work.pages.third
    visit "/display/display_page?page_id=#{test_page.id}"
    page.find('.tabs').click_link("Transcribe")
    expect(page).to have_content("Status")
    page.fill_in 'page_source_text', with: "[[Places|Texas"
    click_button('Save Changes')
    expect(page).to have_content("Subject Linking Error: Wrong number of closing braces")
    page.fill_in 'page_source_text', with: ""
    page.fill_in 'page_source_text', with: "[[Places|Texas]]"
    click_button('Save Changes')
    expect(page).to have_content("Transcription")
    expect(page).to have_content("Texas")
  end

it "enters a bad link - no text" do
    login_as(@user, :scope => :user)
    test_page = @work.pages.fourth
    visit "/display/display_page?page_id=#{test_page.id}"
    page.find('.tabs').click_link("Transcribe")
    expect(page).to have_content("Status")
    page.fill_in 'page_source_text', with: "[[ ]]"
    click_button('Save Changes')
    expect(page).to have_content("Subject Linking Error: Blank tag")
    page.fill_in 'page_source_text', with: ""
    page.fill_in 'page_source_text', with: "[[Places|Texas]]"
    click_button('Save Changes')
    expect(page).to have_content("Transcription")
    expect(page).to have_content("Texas")
  end

it "enters a bad link - no text in category then subject" do
    login_as(@user, :scope => :user)
    test_page = @work.pages.fifth
    visit "/display/display_page?page_id=#{test_page.id}"
    page.find('.tabs').click_link("Transcribe")
    expect(page).to have_content("Status")
    page.fill_in 'page_source_text', with: "[[|Texas]]"
    click_button('Save Changes')
    expect(page).to have_content("Subject Linking Error: Blank subject")
    page.fill_in 'page_source_text', with: ""
    page.fill_in 'page_source_text', with: "[[Places| ]]"
    click_button('Save Changes')
    expect(page).to have_content("Subject Linking Error: Blank text")
    page.fill_in 'page_source_text', with: "[[Places|Texas]]"
    click_button('Save Changes')
    expect(page).to have_content("Transcription")
    expect(page).to have_content("Texas")
  end

end