require 'spec_helper'

RSpec.describe 'Sitemap routes', type: :routing do
  ['/sitemap.xml', '/sitemap_collections.xml', '/sitemap_works.xml', '/sitemap_pages.xml'].each do |path|
    it "does not route #{path}" do
      expect(get: path).not_to be_routable
    end
  end
end
