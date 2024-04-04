require 'spec_helper'

describe "collection metadata", :order => :defined do
  before :each do
    @owner = User.where(login: 'wakanda').first
    @user = User.where(login: 'margaret').first
  end

  it "creates a collection as owner" do
    login_as @owner
    visit dashboard_owner_path
    page.find('a', text: 'Create a Collection').click
    fill_in 'collection_title', with: 'ladi'
    click_button('Create Collection')
    expect(page).to have_content("ladi")
  end

  it "uploads works from a zip file", :js => true do
    login_as @owner
    visit dashboard_owner_path
    page.find('.tabs').click_link("Start A Project")
    page.find(:css, "#document-upload").click
    select("ladi", :from => 'document_upload_collection_id')

    # workaround
    script = "$('#document_upload_file').css({opacity: 100, display: 'block', position: 'relative', left: ''});"
    page.execute_script(script)

    attach_file('document_upload_file', './test_data/uploads/ladi_fixture.zip')
    click_button('Upload File')
    title = find('h1').text
    expect(title).to eq "ladi"
    expect(page).to have_content("Document has been uploaded")
    wait_for_upload_processing
    sleep(10)
  end

  it "uploads metadata for the imported works", :js => true do
    login_as @owner
    c = Collection.where(title: "ladi").first
    visit edit_collection_path(@owner, c)
    page.find('.side-tabs').click_link('Look & Feel')
    expect(page).to have_content("Allow users to browse works within this collection via metadata.")
    visit collection_metadata_upload_path(c)
    expect(page).to have_content("To update metadata for several works within this collection")

    # workaround
    script = "$('#metadata_file').css({opacity: 100, display: 'block', position: 'relative', left: ''});"
    page.execute_script(script)

    attach_file('metadata_file', './test_data/uploads/eaacone_metadata_FromThePage_TestDataset.csv')
    click_button('Upload')
  end

  it "increments occurrences as works are re-imported", :js => true do
    login_as @owner
    c = Collection.where(title: "ladi").first
    filename = c.metadata_coverages.where(key: 'filename').first
    expect(filename.count).to eq 3

    # reupload the same work here.
    visit edit_collection_path(@owner, c)
    page.find('.side-tabs').click_link('Look & Feel')
    expect(page).to have_content("Allow users to browse works within this collection via metadata.")
    visit collection_metadata_upload_path(c)
    expect(page).to have_content("To update metadata for several works within this collection")

    # workaround
    script = "$('#metadata_file').css({opacity: 100, display: 'block', position: 'relative', left: ''});"
    page.execute_script(script)

    attach_file('metadata_file', './test_data/uploads/eaacone_metadata_FromThePage_TestDataset.csv')
    click_button('Upload')
    filename.reload
    expect(filename.count).to eq 3
  end

  it "enables facets", js: true do
    login_as @owner
    c = Collection.where(title: "ladi").first
    visit edit_collection_path(@owner, c)
    page.find('.side-tabs').click_link('Look & Feel')
    page.check("Enable metadata facets")
    page.click_link('Edit Facets')
    expect(page).to have_content("Metadata Facets")
    expect(page).to have_content("Configure metadata facets by reviewing the metadata in your collection and labelling fields to be displayed to transcribers.")
    expect(page).to have_content("filename")
    expect(page).to have_content("field_identifier_local")
  end

  it "allows saving additional metadata" do
    login_as @owner
    c = Collection.where(title: "ladi").first
    visit edit_collection_path(@owner, c)
    page.find('.side-tabs').click_link('Look & Feel')
    click_link "Edit Facets"
    expect(page).to have_content("Metadata Facets")
    expect(page).to have_content("filename")
    fill_in 'metadata_filename_label', with: 'Filename'
    fill_in 'metadata_filename_order', with: 9
    click_button 'Save Metadata'
    expect(page).to have_content("Collection facets updated successfully")
    expect(find_field('metadata_filename_label').value).to eq "Filename"
    expect(find_field('metadata_filename_order').value).to eq "0"
  end

  it "allows a numeric value from 0 to 9 for text type" do
    login_as @owner
    c = Collection.where(title: "ladi").first
    visit edit_collection_path(@owner, c)
    page.find('.side-tabs').click_link('Look & Feel')
    click_link "Edit Facets"
    expect(page).to have_content("Metadata Facets")
    expect(page).to have_content("filename")
    fill_in 'metadata_filename_label', with: 'Filename'
    fill_in 'metadata_filename_order', with: 25
    click_button 'Save Metadata'
    expect(page).to have_content("Order is not included in the list")
  end

  it "allows a numeric value from 0 to 2 for date type" do
    login_as @owner
    c = Collection.where(title: "ladi").first
    visit edit_collection_path(@owner, c)
    page.find('.side-tabs').click_link('Look & Feel')
    click_link "Edit Facets"
    expect(page).to have_content("Metadata Facets")
    expect(page).to have_content("filename")
    fill_in 'metadata_filename_label', with: 'Filename'
    select("date", from: 'metadata_filename_input_type')
    fill_in 'metadata_filename_order', with: 3
    click_button 'Save Metadata'
    expect(page).to have_content("Order is not included in the list")
  end

  it "can't enter an order as a string" do
    login_as @owner
    c = Collection.where(title: "ladi").first
    visit edit_collection_path(@owner, c)
    page.find('.side-tabs').click_link('Look & Feel')
    click_link "Edit Facets"
    expect(page).to have_content("Metadata Facets")
    expect(page).to have_content("filename")
    fill_in 'metadata_filename_label', with: 'Filename'
    fill_in 'metadata_filename_order', with: 'foo'
    click_button 'Save Metadata'
    expect(page).to have_content("Order is not a number")
  end

  it "should not be available/visible for the Individual Researcher plan", js: true do
    logout
    old_account_type=@user.account_type
    @user.account_type='Individual Researcher'
    @user.save
    login_as @user
    c = Collection.where(title: "ladi").first
    visit edit_collection_path(@user, c)
    page.find('.side-tabs').click_link('Look & Feel')
    expect(page).to have_field("Enable metadata facets", disabled: true)
    expect(page.find_link("Edit Facets")).to match_css('[disabled]')
    expect(page).to have_content("Not available for researcher accounts.")
    @user.account_type=old_account_type
    @user.save
  end

  it "deletes a collection" do
    logout
    login_as @owner
    c = Collection.where(title: "ladi").first
    visit edit_collection_path(@owner, c)
    page.find('.side-tabs').click_link('Danger Zone')
    expect(page).to have_content("ladi")
    expect(page).to have_content("Please use caution")
    click_link "Delete Collection"
    expect(page).not_to have_content("ladi")
    expect(c.metadata_coverages).to be_empty
  end
end
