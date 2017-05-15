require 'spec_helper'

describe "document sets", :order => :defined do

  before :all do

    @owner = User.find_by(login: 'margaret')
    @user = User.find_by(login: 'eleanor')
    @collections = @owner.all_owner_collections
    @collection = @collections.last
  end

  before :each do
    @document_sets = DocumentSet.where(owner_user_id: @owner.id)
  end

  it "adds new document sets" do
    login_as(@owner, :scope => :user)
    visit dashboard_owner_path
    doc_set = DocumentSet.where(owner_user_id: @owner.id).count
    page.find('.maincol').find('a', text: @collection.title).click
    page.find('.tabs').click_link("Settings")
    page.find('.button', text: 'Create Document Sets').click
    expect(page).to have_content('Create a Document Set')
    page.find('.button', text: 'Create a Document Set').click
    page.fill_in 'document_set_title', with: "Test Document Set 1"
    page.find_button('Create Document Set').click
    expect(page).to have_content("Assign Works to Document Sets")
    expect(page).to have_content("Test Document Set 1")
    after_doc_set = DocumentSet.where(owner_user_id: @owner.id).count
    expect(after_doc_set).to eq (doc_set + 1)
    doc_set = DocumentSet.where(owner_user_id: @owner.id).count
    page.find('.button', text: 'Create a Document Set').click
    page.fill_in 'document_set_title', with: "Test Document Set 2"
    page.find_button('Create Document Set').click
    expect(page).to have_content("Test Document Set 2")
    after_doc_set = DocumentSet.where(owner_user_id: @owner.id).count
    expect(after_doc_set).to eq (doc_set + 1)

  end

  it "adds works to document sets" do
    login_as(@owner, :scope => :user)
    visit dashboard_owner_path
    page.find('.maincol').find('a', text: @collection.title).click
    page.find('.tabs').click_link("Sets")
    expect(page).to have_content("Document Sets for #{@collection.title}")
    page.check("work_assignment_#{@document_sets.first.id}_#{@collection.works.first.id}")
    page.check("work_assignment_#{@document_sets.first.id}_#{@collection.works.second.id}")
    page.check("work_assignment_#{@document_sets.last.id}_#{@collection.works.last.id}")
    page.find_button('Save').click
  end

  it "edits a document set" do
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
    page.check 'Public'
    page.find_button('Save Document Set').click
    expect(page).to have_content("Document Sets for #{@collection.title}")
    expect(page).to have_content(@document_sets.first.title)
    within(page.find('#sets')) do
      within(page.find('tr', text: @document_sets.first.title)) do
        expect(page).to have_content("Public")
      end
    end
  end

  it "views document sets" do
    #need to restrict collection and see what the user can see
    login_as(@user, :scope => :user)
    visit dashboard_path
    @collections.each do |c|
      expect(page).to have_content(c.title)
    end
    @document_sets.each do |set|
      expect(page).to have_content(set.title)
    end
    doc_set = @document_sets.last
    page.find('.maincol').find('a', text: doc_set.title).click
    expect(page).to have_content("Overview")
    expect(page).to have_content(@collection.works.first.id)
    expect(page).to have_content(@collection.works.second.id)
    expect(page).to have_content(doc_set.works.first.title)
    page.find('.tabs').click_link('Statistics')
    expect(page).to have_content(doc_set.title)
    expect(page).to have_content("Last 7 Days Statistics")

  end

  it "deletes a document set" do
    login_as(@owner, :scope => :user)
    count = @document_sets.count
    visit dashboard_owner_path
    page.find('.maincol').find('a', text: @collection.title).click
    page.find('.tabs').click_link("Sets")
    expect(page).to have_content("Document Sets for #{@collection.title}")
    within(page.find('#sets')) do
      within(page.find('tr', text: @document_sets.first.title)) do
        page.find('a', text: 'Delete').click
      end
    end
    sets = DocumentSet.all.count
    expect(sets).to eq (count - 1)
    expect(page).not_to have_content(@document_sets.first.title)
    expect(page).to have_content(@document_sets.last.title)
  end

end