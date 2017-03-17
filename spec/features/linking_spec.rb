require 'spec_helper'

describe "subject linking" do

  before :all do
    @owner = User.find_by(login: OWNER)
    @user = User.find_by(login: USER)
    @collection_ids = Deed.where(user_id: @user.id).distinct.pluck(:collection_id)
    @collections = Collection.where(id: @collection_ids)
    @collection = @collections.first
    @work = @collection.works.first
  end

  before :each do
    login_as(@user, :scope => :user)
  end    

  #it checks to make sure the subject is on the page
  it "looks at subjects in a collection" do
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

  it "edits a subject's description" do 
    article = Article.first
    visit "/article/show?article_id=#{article.id}"
    expect(page).to have_content("Description")
    #this will fail if a description is already entered
    click_link("Edit the description in the settings tab")
    expect(page).to have_content("Description")
    expect(page).not_to have_content("Related Subjects")
    expect(page).not_to have_content("Delete Subject")
    page.fill_in 'article_source_text', with: "This is the text about my article."
    click_button('Save Changes')
    expect(page).to have_content("This is the text about my article.")
  end

  it "deletes a subject" do
    logout(:user)
    login_as(@owner, :scope => :user)
    collection = @collections.last
    visit "/collection/show?collection_id=#{collection.id}"
    page.find('.tabs').click_link("Subjects")
    page.find('a', text: "Testing").click
    page.find('.tabs').click_link("Settings")
    click_link('Delete Subject')
    expect(page.find('.flash_message')).to have_content("You must remove all referring links")
    page.find('a', text: "Show pages that mention").click
    page.find('.work-page_title').find('a').click
    page.find('.tabs').click_link("Transcribe")
    page.fill_in 'page_source_text', with: ""
    click_button('Save Changes')
    expect(page).to have_content("Facsimile")
    click_link(collection.title)
    page.find('.tabs').click_link("Subjects")
    page.find('a', text: "Testing").click
    expect(page).not_to have_content("Show pages that mention Testing in all works")
    page.find('.tabs').click_link("Settings")
    click_link('Delete Subject')
    expect(page).to have_content("People")
    expect(page).to have_content("There are no subjects for the category selected")
  end

  it "links a categorized subject" do
    test_page = @work.pages.last
    visit "/display/display_page?page_id=#{test_page.id}"
    page.find('.tabs').click_link("Transcribe")
    expect(page).to have_content("Status")
    page.fill_in 'page_source_text', with: "[[Places|Texas]]"
    click_button('Save Changes')
    expect(page).to have_content("Transcription")
    expect(page).to have_content("Texas")
    links = PageArticleLink.where("page_id = ? AND text_type = ?", test_page.id, "transcription").count
    expect(links).to eq 1
    #check to see if the links are regenerating on save
    page.find('.tabs').click_link("Transcribe")
    expect(page).to have_content("Status")
    page.fill_in 'page_source_text', with: "[[Places|Texas]]"
    click_button('Save Changes')
    expect(page).to have_content("Texas")
    links = PageArticleLink.where("page_id = ? AND text_type = ?", test_page.id, "transcription").count
    expect(links).to eq 1
    #check the tooltip to explore a subject
    page.find('a', text: 'Texas').click
    expect(page).to have_content("Related Subjects")
    expect(page).to have_content("Texas")
    #check that it's creating an initial version
    page.find('.tabs').click_link("Versions")
    expect(page).to have_content("1 revision")
  end

  it "enters a bad link - no closing braces" do
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
    test_page = @work.pages.fourth
    visit "/display/display_page?page_id=#{test_page.id}"
    page.find('.tabs').click_link("Transcribe")
    expect(page).to have_content("Status")
    #no text in the link
    page.fill_in 'page_source_text', with: "[[ ]]"
    click_button('Save Changes')
    expect(page).to have_content("Subject Linking Error: Blank tag")
    #no text in the category
    page.fill_in 'page_source_text', with: "[[|Texas]]"
    click_button('Save Changes')
    expect(page).to have_content("Subject Linking Error: Blank subject")
    #no text in the subject
    page.fill_in 'page_source_text', with: "[[Places| ]]"
    click_button('Save Changes')
    expect(page).to have_content("Subject Linking Error: Blank text")
    page.fill_in 'page_source_text', with: "[[Places|Texas]]"
    click_button('Save Changes')
    expect(page).to have_content("Transcription")
    expect(page).to have_content("Texas")
  end

  it "enters a bad link - single starting bracket" do
    test_page = @work.pages.third
    visit "/display/display_page?page_id=#{test_page.id}"
    page.find('.tabs').click_link("Transcribe")
    expect(page).to have_content("Status")
    page.fill_in 'page_source_text', with: "[[Texas[?]]"
    click_button('Save Changes')
    expect(page).to have_content("Subject Linking Error: Unclosed bracket")
    page.fill_in 'page_source_text', with: ""
    page.fill_in 'page_source_text', with: "[[Places|Texas]]"
    click_button('Save Changes')
    expect(page).to have_content("Transcription")
    expect(page).to have_content("Texas")
  end

  it "enters a bad link - triple brackets" do
    test_page = @work.pages.third
    visit "/display/display_page?page_id=#{test_page.id}"
    page.find('.tabs').click_link("Transcribe")
    expect(page).to have_content("Status")
    page.fill_in 'page_source_text', with: "[[[Texas]]]"
    click_button('Save Changes')
    expect(page).to have_content("Subject Linking Error: Tags should be created using 2 brackets, not 3")
    page.fill_in 'page_source_text', with: ""
    page.fill_in 'page_source_text', with: "[[Places|Texas]]"
    click_button('Save Changes')
    expect(page).to have_content("Transcription")
    expect(page).to have_content("Texas")
  end

  it "creates a link that includes quotes" do
    test_page = @work.pages.third
    visit "/display/display_page?page_id=#{test_page.id}"
    page.find('.tabs').click_link("Transcribe")
    expect(page).to have_content("Status")
    page.fill_in 'page_source_text', with: "[[Places|\"Houston\"]]"
    click_button('Save Changes')
    expect(page).to have_content("Houston")
  end

  it "links subjects on a translation" do
    translate_work = Work.where("supports_translation = ? && restrict_scribes = ?", true, false).first
    test_page = translate_work.pages.first
    visit "/display/display_page?page_id=#{test_page.id}"
    page.find('.tabs').click_link("Translate")
    expect(page).to have_content("Translation")
    page.fill_in 'page_source_translation', with: "[[Places|Texas]]"
    click_button('Save Changes')
    expect(page).to have_content("Translation")
    expect(page).to have_content("Texas")
    links = PageArticleLink.where("page_id = ? AND text_type = ?", test_page.id, "translation").count
    expect(links).to eq 1
  #check to see if the links are regenerating on save
    page.find('.tabs').click_link("Translate")
    expect(page).to have_content("Translation")
    page.fill_in 'page_source_translation', with: "[[Places|Texas]]"
    click_button('Save Changes')
    expect(page).to have_content("Texas")
    links = PageArticleLink.where("page_id = ? AND text_type = ?", test_page.id, "translation").count
    expect(links).to eq 1
  end

  it "tests autolinking in transcription" do
    link_work = @collection.works.second
    link_page = link_work.pages.first
    visit "/display/display_page?page_id=#{link_page.id}"
    page.find('.tabs').click_link("Transcribe")
    #make sure the autolink doesn't duplicate a link
    expect(page).to have_content("[[John Samuel Smith|John]]")
    expect(page).to have_content("Mrs. Davis")
    click_button('Autolink')
    expect(page).not_to have_content("[[John [[Samuel Jones|Samuel]] Smith|John]]")
    expect(page).not_to have_content("[[Mrs.]]")
    expect(page).to have_content("Mrs. Davis")
    #make sure it doesn't autolink something that has no subject
    page.fill_in 'page_source_text', with: "Houston"
    click_button('Autolink')
    expect(page).not_to have_content("[[Places|Houston]]")
    #check that it links if there is a subject
    page.fill_in 'page_source_text', with: "Texas"
    click_button('Autolink')
    expect(page).to have_content("[[Places|Texas]]")
  end

  it "tests autolinking in translation" do
    translate_work = Work.where("supports_translation = ? && restrict_scribes = ?", true, false).first
    test_page = translate_work.pages.last
    visit "/display/display_page?page_id=#{test_page.id}"
    page.find('.tabs').click_link("Translate")
    #make sure it doesn't autolink something that has no subject
    page.fill_in 'page_source_translation', with: "Houston"
    click_button('Autolink')
    expect(page).not_to have_content("[[Places|Houston]]")
    #check that it links if there is a subject
    page.fill_in 'page_source_translation', with: "Texas"
    click_button('Autolink')
    expect(page).to have_content("[[Places|Texas]]")
  end

end