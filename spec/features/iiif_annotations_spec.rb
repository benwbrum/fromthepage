require 'spec_helper'

describe "IIIF Annotations API" do

  before :all do
    @owner = User.find_by(login: OWNER)
    @collection = @owner.all_owner_collections.first
    @work = @collection.works.last
    @page = @work.pages.first
  end

  it "should return OK for transcription" do
    visit collection_annotation_page_transcription_html_path(@owner, @collection, @work, @page)
  end
  it "should return OK for translation" do
    visit collection_annotation_page_translation_html_path(@owner, @collection, @work, @page)
  end
end