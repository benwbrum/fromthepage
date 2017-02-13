require 'spec_helper'

describe "collection related tasks", :order => :defined do

  before :all do

    @user = User.find_by(login: 'margaret')
    @collections = @user.all_owner_collections
    @collection = @collections.first
    @works = @user.owner_works
    
  end

  it "exports a collection" do
    login_as(@user, :scope => :user)
    visit dashboard_owner_path
    page.find('.collection_title', text: @collection.title).click_link(@collection.title)
    page.find('.tabs').click_link("Export")
    expect(page).to have_content("Export All Works")
    expect(page).to have_content(@collection.works.first.title)
    page.find('#btnExportAll').click
    expect(page.response_headers['Content-Type']).to eq 'application/zip'
  end

end