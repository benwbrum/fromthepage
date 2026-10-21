require 'spec_helper'

RSpec.describe 'Sitemap routes', type: :routing do
  ['/sitemap.xml', '/sitemap_collections.xml', '/sitemap_works.xml', '/sitemap_pages.xml'].each do |path|
    it "routes #{path} to the user profile fallback" do
      user_id = File.basename(path, '.xml')

      expect(get: path).to route_to(
        controller: 'user',
        action: 'profile',
        user_id: user_id,
        format: 'xml'
      )
    end
  end
end
