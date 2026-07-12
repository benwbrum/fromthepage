require 'spec_helper'

RSpec.describe 'robots.txt' do
  let(:robots_txt) { Rails.root.join('public/robots.txt').read }

  it 'blocks version-history endpoints from crawler discovery' do
    expect(robots_txt).to include("Disallow: /page_version/\n")
    expect(robots_txt).to include("Disallow: /article_version/\n")
  end

  it 'keeps public display URLs crawlable' do
    expect(robots_txt).to include("Allow: /*/display/*\n")
    expect(robots_txt).to include("Allow: /*/*/*/display/*\n")
  end
end
