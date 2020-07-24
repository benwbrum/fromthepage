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
    expect(page).to have_content("Allow users to browse works within this collection via metadata.")
    click_link "Upload Metadata"
    expect(page).to have_content("To update metadata for several works within this collection")

    # workaround
    script = "$('#metadata_file').css({opacity: 100, display: 'block', position: 'relative', left: ''});"
    page.execute_script(script)

    attach_file('metadata_file', './test_data/uploads/eaacone_metadata_FromThePage_TestDataset.csv')
    click_button('Upload')
  end

  it "enables facets" do
    login_as @owner
    c = Collection.where(title: "ladi").first
    visit edit_collection_path(@owner, c)
    click_link "Enable Facets"
    expect(page).to have_content("Facets")
    click_link "Facets"
    expect(page).to have_content("Metadata Facets")
    expect(page).to have_content("Configure metadata facets by reviewing the metadata currently present in your collection, and selecting fields to be displayed to users.")
    expect(page).to have_content("filename")
    expect(page).to have_content("field_identifier_local")
  end

  it "should not be available/visible for the Individual Researcher plan" do
    logout
    login_as @user
    c = Collection.where(title: "ladi").first
    visit edit_collection_path(@user, c)
    expect(page).not_to have_content("Metadata")
  end

  it "deletes a collection" do
    logout
    login_as @owner
    c = Collection.where(title: "ladi").first
    visit edit_collection_path(@owner, c)
    expect(page).to have_content("ladi")
    click_link "Delete Collection"
    expect(page).not_to have_content("ladi")
    expect(c.metadata_coverages).to be_empty
  end
end
