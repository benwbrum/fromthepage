=begin
require 'spec_helper'

describe "owner actions", :order => :defined do
  Capybara.javascript_driver = :webkit

  before :all do

    @user = User.find_by(login: 'minerva')
    @collections = @user.all_owner_collections
    @collection = @collections.last
    @works = @user.owner_works
  end

  it "adds an owner to a collection", :js => true do
    login_as(@user, :scope => :user)
    visit "/collection/show?collection_id=#{@collection.id}"
    page.find('.tabs').click_link("Settings")
    page.find('.user-select-form').click

    select 'Ron', from: 'user_id'
    #page.find('.user-select-form').submit

    #page.find('#test').submit
    save_and_open_page

    #page.find('.user-select-form').find('select2:select')
    #cannot work out how to enable button!!!
    #print page.find('button', text: 'Add')['disabled'].text
    #page.find('button', text: 'Add').trigger(:submit)
    #save_and_open_screenshot    

    #page.find(('button', text: 'Add')['disabled']).set(false)
    
    #bar = page.find('button', text: 'Add')
    #bar.value
    #bar.set(:disabled, "enabled")
    #page.execute_script("$('button', text: 'Add').attr('disabled', 'false')")

    #save_and_open_screenshot
    #save_and_open_page

    #page.find('button', text: 'Add')
    #page.find('.user-select-form').submit

    #useful code from another test
    #page.execute_script(%Q('$("#revert").trigger("click")'))


  end

  it "checks rights of added owner" do
    @owner2 = User.find_by(login: 'ron')
    login_as(@owner2, :scope => :user)
    visit "/collection/show?collection_id=#{@collection.id}"
    expect(page.find('.tabs')).to have_content('Settings')
    page.find('.tabs').click_link('Contributors')
    expect(@owner2.owner).to eq true
    #login as new owner, make sure can see tabs, add work
  end

end
=end