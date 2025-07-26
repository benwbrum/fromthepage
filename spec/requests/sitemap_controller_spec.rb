require 'rails_helper'

RSpec.describe SitemapController, type: :request do
  before do
    # Create test data
    @owner = create(:user, :owner)
    @collection = create(:collection, owner: @owner, is_active: true, restricted: false)
    @work = create(:work, collection: @collection)
    @page = create(:page, work: @work, status: 'transcribed')
  end

  describe "GET /sitemap.xml" do
    it "returns valid XML sitemap index" do
      get "/sitemap.xml"
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("application/xml")
      
      # Parse XML to validate structure
      doc = Nokogiri::XML(response.body)
      expect(doc.at_xpath("//sitemapindex")).to be_present
      expect(doc.xpath("//sitemap").count).to eq(3) # collections, works, pages
    end
  end

  describe "GET /sitemap_collections.xml" do
    it "returns collections sitemap with correct URLs" do
      get "/sitemap_collections.xml"
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("application/xml")
      
      doc = Nokogiri::XML(response.body)
      urls = doc.xpath("//url/loc").map(&:text)
      
      expected_url = "#{request.protocol}#{request.host_with_port}/#{@owner.slug}/#{@collection.slug}"
      expect(urls).to include(expected_url)
    end
  end

  describe "GET /sitemap_works.xml" do
    it "returns works sitemap with correct URLs" do
      get "/sitemap_works.xml"
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("application/xml")
      
      doc = Nokogiri::XML(response.body)
      urls = doc.xpath("//url/loc").map(&:text)
      
      expected_url = "#{request.protocol}#{request.host_with_port}/#{@owner.slug}/#{@collection.slug}/#{@work.slug}"
      expect(urls).to include(expected_url)
    end
  end

  describe "GET /sitemap_pages.xml" do
    it "returns pages sitemap with correct URLs" do
      get "/sitemap_pages.xml"
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("application/xml")
      
      doc = Nokogiri::XML(response.body)
      urls = doc.xpath("//url/loc").map(&:text)
      
      expected_url = "#{request.protocol}#{request.host_with_port}/#{@owner.slug}/#{@collection.slug}/#{@work.slug}/display/#{@page.id}"
      expect(urls).to include(expected_url)
    end
  end

  describe "restricted collections" do
    it "excludes restricted collections from sitemap" do
      restricted_collection = create(:collection, owner: @owner, is_active: true, restricted: true)
      
      get "/sitemap_collections.xml"
      
      doc = Nokogiri::XML(response.body)
      urls = doc.xpath("//url/loc").map(&:text)
      
      restricted_url = "#{request.protocol}#{request.host_with_port}/#{@owner.slug}/#{restricted_collection.slug}"
      expect(urls).not_to include(restricted_url)
    end
  end

  describe "blank and new pages" do
    it "excludes blank pages from sitemap" do
      blank_page = create(:page, work: @work, status: 'blank')
      
      get "/sitemap_pages.xml"
      
      doc = Nokogiri::XML(response.body)
      urls = doc.xpath("//url/loc").map(&:text)
      
      blank_url = "#{request.protocol}#{request.host_with_port}/#{@owner.slug}/#{@collection.slug}/#{@work.slug}/display/#{blank_page.id}"
      expect(urls).not_to include(blank_url)
    end
    
    it "excludes new status pages from sitemap" do
      new_page = create(:page, work: @work, status: 'new')
      
      get "/sitemap_pages.xml"
      
      doc = Nokogiri::XML(response.body)
      urls = doc.xpath("//url/loc").map(&:text)
      
      new_url = "#{request.protocol}#{request.host_with_port}/#{@owner.slug}/#{@collection.slug}/#{@work.slug}/display/#{new_page.id}"
      expect(urls).not_to include(new_url)
    end
  end
end