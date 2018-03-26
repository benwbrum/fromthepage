require 'spec_helper'

describe "needs review", :order => :defined do
  Capybara.javascript_driver = :webkit

  before :all do
    @owner = User.find_by(login: OWNER)
    @user = User.find_by(login: USER)
    @collection = Collection.second
    @work = @collection.works.third
    @page1 = @work.pages.first
    @page2 = @work.pages.second
    @page3 = @work.pages.third
    @page4 = @work.pages.fourth
    @page5 = @work.pages.fifth
    @page6 = @work.pages.last
  end

  before :each do
    login_as(@user, :scope => :user)
  end

  it "sets the work to translation" do
    logout(@user)
    login_as(@owner, :scope => :user)
    visit "/work/edit?work_id=#{@work.id}"
    expect(page).to have_content(@work.title)
    page.check('work_supports_translation')
    click_button('Save Changes')
    expect(Work.find_by(id: @work.id).supports_translation).to be true
    logout(@owner)
  end

  it "marks pages blank" do
    visit collection_read_work_path(@work.collection.owner, @work.collection, @work)
    expect(@page1.status).to be_nil
    expect(@page2.status).to be_nil
    expect(page).to have_content(@work.title)
    page.find('.work-page_title', text: @page1.title).click_link(@page1.title)
    page.check('page_mark_blank')
    click_button('Save Changes')
    expect(page).to have_content("This page is blank")
    expect(Page.find_by(id: @page1.id).status).to eq ('blank')
    expect(Page.find_by(id: @page1.id).translation_status).to eq ('blank')
    page.find('.page-nav_next').click
    expect(page).to have_content(@page2.title)
    expect(page).to have_content("This page is not transcribed")
    page.find('a', text: 'mark the page blank').click
    expect(page).to have_content("This page is blank")
    expect(page).to have_content("This page is blank")
    expect(Page.find_by(id: @page2.id).status).to eq ('blank')
    expect(Page.find_by(id: @page2.id).translation_status).to eq ('blank')
  end

  it "marks translated pages as blank" do
    visit collection_read_work_path(@work.collection.owner, @work.collection, @work)
    expect(page).to have_content(@work.title)
    expect(@page3.translation_status).to be_nil
    page.find('.work-page_title', text: @page3.title).click_link(@page3.title)
    page.find('.tabs').click_link("Translate")
    page.check('page_mark_blank')
    click_button('Save Changes')
    expect(page).to have_content("This page is blank")
    expect(Page.find_by(id: @page3.id).translation_status).to eq ('blank')
  end

  it "marks pages as needing review" do
    visit collection_path(@collection.owner, @collection)
    expect(@page4.status).to be_nil
    expect(@page5.status).to be_nil
    expect(page).to have_content(@collection.title)
    click_link @work.title
    page.find('.work-page_title', text: @page4.title).click_link(@page4.title)
    page.fill_in 'page_source_text', with: "Review Text"
    page.check('page_needs_review')
    click_button('Save Changes')
    expect(page).to have_content("This page has been marked as \"needs review\"")
    page.click_link("Overview")
    expect(page).to have_content("Review Text")
    expect(page).to have_content("Transcription")
    expect(Page.find_by(id: @page4.id).status).to eq ('review')
    page.find('.page-nav_next').click
    expect(page).to have_content(@page5.title)
    page.find('.tabs').click_link("Transcribe")
    page.fill_in 'page_source_text', with: "Review Text 2"
    page.check('page_needs_review')
    click_button('Save Changes')
    expect(page).to have_content("Review Text 2")
    expect(page).to have_content("Transcription")
    expect(Page.find_by(id: @page5.id).status).to eq ('review')
  end

  it "marks translated pages as needing review" do
    visit "/display/display_page?page_id=#{@page6.id}"
    expect(@page6.translation_status).to be_nil
    page.find('.tabs').click_link("Translate")
    page.fill_in 'page_source_translation', with: "Review Translate Text"
    page.check('page_needs_review')
    click_button('Save Changes')
    expect(page).to have_content("This page has been marked as \"needs review\"")
    page.click_link("Overview")
    page.click_link('Show Translation')
    expect(page).to have_content("Review Translate Text")
    expect(page).to have_content("Translation")
    expect(Page.find_by(id: @page6.id).translation_status).to eq ('review')
  end

  it "filters list of review pages" do
    visit collection_read_work_path(@work.collection.owner, @work.collection, @work)
    expect(page).to have_content(@work.title)
    pages = @work.pages.limit(5)
    pages.each do |p|
      expect(page.find('.maincol')).to have_selector('a', text: p.title)
    end
    #look at review list
    click_button('Pages That Need Review')
    expect(page.find('.maincol')).to have_selector('a', text: @page4.title)
    expect(page.find('.maincol')).to have_selector('a', text: @page5.title)
    expect(page.find('.maincol')).not_to have_selector('a', text: @page1.title)
    expect(page.find('.maincol')).not_to have_selector('a', text: @page2.title)
    expect(page.find('.maincol')).not_to have_selector('a', text: @page3.title)
    expect(page).to have_button('View All Pages')
    expect(page.find('.pagination_info')).to have_content(@work.pages.review.count)

    #return to original list
    click_button('View All Pages')
    pages = @work.pages.limit(5)
    pages.each do |p|
      expect(page.find('.maincol')).to have_selector('a', text: p.title)
    end
    expect(page).to have_button('Pages That Need Review')
    expect(page.find('.pagination_info')).to have_content(@work.pages.count)
    #look at translated review list
    click_button('Translations That Need Review')
    expect(page.find('.maincol')).to have_selector('a', text: @page6.title)
    expect(page.find('.maincol')).not_to have_selector('a', text: @page3.title)
    expect(page.find('.maincol')).not_to have_selector('a', text: @page4.title)
    expect(page.find('.maincol')).not_to have_selector('a', text: @page5.title)
    expect(page).to have_button('View All Pages')
    expect(page.find('.pagination_info')).to have_content(@work.pages.translation_review.count)
  end

  it "views collection pages that need review" do
    login_as(@user, :scope => :user)
    visit collection_path(@collection.owner, @collection)
    expect(page).to have_content("About")
    expect(page).to have_content("Works")
    page.click_link("Pages That Need Review")
    expect(page).to have_selector('h3', text: "Pages That Need Review")
    #make sure a page exists; don't specify which one
    expect(page).to have_selector('.work-page')
    click_link("Return to collection")
    expect(page).to have_content("About")
    expect(page).to have_content("Works")
  end

  it "checks collection overview stats view" do
    visit collection_path(@collection.owner, @collection)
    #show all works before checking for stats
    page.click_link("Show All")
    @collection.works.each do |w|
      if w.supports_translation
        wording = "translated"
        completed = w.work_statistic.pct_translation_completed.round
        review = w.work_statistic.pct_translation_needs_review.round
        indexed = w.work_statistic.pct_translation_annotated.round
      else
        if w.ocr_correction
          wording = "corrected"
        else
          wording = "transcribed"
        end
        completed = w.work_statistic.pct_completed.round
        review = w.work_statistic.pct_needs_review.round
        indexed = w.work_statistic.pct_annotated.round
      end

      stats = page.find('.collection-work', text: w.title).find('.collection-work_stats') 
      expect(stats).to have_content("#{indexed}% indexed")
      expect(stats).to have_content("#{completed}% #{wording}")
      unless review == 0
        expect(stats).to have_content("#{review}% needs review")
      end
      #check for the existence of the progress bar
      stats.find('.progress')
    end
  end

  it "checks statistics in works list" do
    logout(@user)
    login_as(@owner, :scope => :user)
    visit collection_works_list_path(@collection.owner, @collection)
    expect(page).to have_content(@collection.title)
    @collection.works.each do |w|
      if w.supports_translation
        wording = "translated"
        completed = w.work_statistic.pct_translation_completed.round
        review = w.work_statistic.pct_translation_needs_review.round
      else
        if w.ocr_correction
          wording = "corrected"
        else
          wording = "transcribed"
        end
        completed = w.work_statistic.pct_completed.round
        review = w.work_statistic.pct_needs_review.round
      end
      stats = w.work_statistic
      list = page.find('.collection-work-stats').find('li', text: w.title)
      expect(list).to have_content(w.title)
      expect(list).to have_content(w.pages.count)
      expect(list.find('span', text: 'indexed')).to have_content(stats.pct_annotated.round)
      expect(list).to have_content("#{completed}% #{wording}")
      unless review == 0
        expect(list.find('span', text: 'needs review')).to have_content(review)
      end
    end
  end

  it "marks pages as no longer needing review" do
    @page4 = @work.pages.fourth
    visit collection_path(@collection.owner, @collection)
    expect(@page4.status).to eq ('review')
    expect(page).to have_content(@collection.title)
    page.find('.collection-work_title', text: @work.title).click_link
    page.find('.work-page_title', text: @page4.title).click_link(@page4.title)
    page.find('.tabs').click_link("Transcribe")
    page.fill_in 'page_source_text', with: "Change Review Text"
    page.uncheck('page_needs_review')
    click_button('Save Changes')
    expect(page).not_to have_content("This page has been marked as \"needs review\"")
    expect(page).to have_content("Change Review Text")
    expect(page).to have_content("Transcription")
    expect(Page.find_by(id: @page4.id).status).to eq ('transcribed')
    expect(Page.find_by(id: @page5.id).status).to eq ('review')
  end

  it "marks translated pages as no longer needing review" do
    @page6 = @work.pages.last
    visit "/display/display_page?page_id=#{@page6.id}"
    expect(@page6.translation_status).to eq ('review')
    page.find('.tabs').click_link("Translate")
    page.fill_in 'page_source_translation', with: "Change Review Translate Text"
    page.uncheck('page_needs_review')
    click_button('Save Changes')
    expect(page).not_to have_content("This page has been marked as \"needs review\"")
    page.click_link("Overview")
    page.click_link('Show Translation')
    expect(page).to have_content("Change Review Translate Text")
    expect(page).to have_content("Translation")
    expect(Page.find_by(id: @page6.id).translation_status).to eq ('translated')
  end

  it "marks pages not blank" do
    visit collection_read_work_path(@work.collection.owner, @work.collection, @work)
    expect(page).to have_content("This page is blank")
    @page1 = @work.pages.first
    expect(@page1.status).to eq ('blank')
    expect(page).to have_content(@work.title)
    page.find('.work-page_title', text: @page1.title).click_link(@page1.title)
    expect(page).to have_content("This page is blank")
    page.find('.tabs').click_link("Transcribe")
    page.uncheck('page_mark_blank')
    click_button('Save Changes')
    expect(page).not_to have_content("This page is blank")
    expect(Page.find_by(id: @page1.id).status).to be_nil
    expect(Page.find_by(id: @page1.id).translation_status).to be_nil
  end

  it "checks needs review/blank checkboxes", :js => true do
    @page1 = @work.pages.first
    expect(@page1.status).to be_nil
    visit collection_transcribe_page_path(@work.collection.owner, @work.collection, @work, @page1.id)
    expect(page.find('#page_needs_review')).not_to be_checked
    expect(page.find('#page_mark_blank')).not_to be_checked
    page.check('page_needs_review')
    page.check('page_mark_blank')
    expect(page.find('#page_needs_review')).not_to be_checked
    expect(page.find('#page_mark_blank')).to be_checked
    page.check('page_needs_review')
    expect(page.find('#page_needs_review')).to be_checked
    expect(page.find('#page_mark_blank')).not_to be_checked
  end

  it "sets a collection to needs review workflow" do
    login_as(@owner, :scope => :user)
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Settings")
    page.check('collection_review_workflow')
    click_button('Save Changes')
    review_page = @work.pages.first
    expect(review_page.status).to be_nil
    expect(review_page.translation_status).to be_nil
    visit collection_transcribe_page_path(@work.collection.owner, @work.collection, @work, review_page.id)
    page.fill_in 'page_source_text', with: "Needs Review Workflow Text"
    click_button('Save Changes')
    expect(page).to have_content("Needs Review Workflow Text")
    expect(Page.find_by(id: review_page.id).status).to eq ('review')
    visit collection_translate_page_path(@work.collection.owner, @work.collection, @work, review_page.id)
    page.fill_in 'page_source_translation', with: "Translation Needs Review Workflow Text"
    click_button('Save Changes')
    expect(page).to have_content("Translation Needs Review Workflow Text")
    expect(Page.find_by(id: review_page.id).translation_status).to eq ('review')
  end

end
