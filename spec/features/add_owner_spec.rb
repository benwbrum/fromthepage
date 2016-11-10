require 'spec_helper'

describe "owner actions", :order => :defined do
    Capybara.javascript_driver = :webkit

  before :all do

    @user = User.find_by(login: 'minerva')
    @collections = @user.all_owner_collections
    @collection = @collections.first
    @works = @user.owner_works
  end

  it "adds an owner to a collection" do #, :js => true do
    collection = @collections.last
    login_as(@user, :scope => :user)
    visit "/collection/show?collection_id=#{collection.id}"
    page.find('.tabs').click_link("Settings")
    #page.find('.user-select-form').click
    page = page.find('#user_id')
    select 'Harry', from page
    #select 'Harry', from: '#user_id', visible: false
save_and_open_page
    #expect(page.find('.user-select-form')).to have_content('Add')
    #element = page.find('.user-select-form')
#javascript doesn't seem to be loading correctly, so this doesn't work.
#    execute_script("$('.user-select-form select')")

    #select 'Harry', from: 'user_id'
    #this requires the javascript setup which i haven't yet enabled.
    #click_button 'Add', visible: false

  end

  it "checks rights of added owner" do
    #login as new owner, make sure can see tabs, add work
  end
end