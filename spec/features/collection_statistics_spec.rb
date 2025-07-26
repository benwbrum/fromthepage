require 'spec_helper'

describe "collection statistics" do
  let(:owner) { User.where(login: 'carlos').first }
  let(:user) { User.where(login: 'jose').first }

  describe "as owner" do
    before(:each) { login_as owner }

    it "creates a collection" do
      visit dashboard_owner_path
      page.find('a', text: 'Create a Collection').click
      fill_in 'collection_title', with: 'Historia del Paraguay'
      click_button('Create Collection')
      expect(page).to have_content("Historia del Paraguay")
    end

    it "can view the Mailing List Export link" do
      # Create the collection for this test
      create(:collection, title: "Historia del Paraguay", owner: owner)
      
      visit dashboard_summary_path
      expect(page).to have_content("Collaborators")
      expect(page).to have_css('#mailing-list-export-submit')
    end

    it "adds user to the owners group" do
      # Create the collection for this test
      collection = create(:collection, title: "Historia del Paraguay", owner: owner)
      
      visit dashboard_owner_path
      expect(page).to have_content("Historia del Paraguay")
      click_link "Historia del Paraguay", match: :first
      expect(page).to have_content("Settings")
      click_link "Settings"
      page.find('.side-tabs').click_link('Privacy & Access')
      page.click_link 'Edit Owners'
      select("jose - jose@example.org", from: "user_id").select_option
      within(".user-select-form") do
        click_button "Add"
      end
      user.reload
      expect(user.owner).to be(true)
    end
  end

  describe "as regular user" do
    context "when not an owner" do
      it "cannot view the Mailing List Export link" do
        # Create the collection but don't make user an owner
        create(:collection, title: "Historia del Paraguay", owner: owner)
        
        login_as user
        visit dashboard_summary_path
        expect(page).not_to have_css('#mailing-list-export-submit')
      end
    end

    context "when promoted to owner" do
      it "can view the Mailing List Export link" do
        # Set up user as owner for this test
        user.update!(owner: true)
        create(:collection, title: "Historia del Paraguay", owner: owner)
        
        login_as user
        visit dashboard_summary_path
        expect(page).to have_css('#mailing-list-export-submit')
      end
    end
  end
end
