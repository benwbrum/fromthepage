require 'spec_helper'

describe "check uploads" do
#    Capybara.javascript_driver = :webkit

  before :all do

    @user = User.find_by(login: 'minerva')
    @collections = @user.all_owner_collections
    @collection = @collections.first
    @work = Work.find_by(title: fps1)
  end
=begin
  it "checks that the file has been uploaded" do
    visit "/collection/show?collection_id=#{@collections.first.id}"
    save_and_open_page
    expect(page).to have_content(@work.title)
  end
=end
end
