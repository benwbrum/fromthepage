require 'spec_helper'

RSpec.describe IaLeaf, type: :model do
  let(:ia_work) { IaWork.new(book_id: 'sample_book') }
  let(:leaf) { described_class.new(ia_work: ia_work, leaf_number: 12) }

  it 'builds archive.org image URLs' do
    expect(leaf.thumb_url).to eq('https://www.archive.org/download/sample_book/page/leaf12_thumb.jpg')
    expect(leaf.facsimile_url).to eq('https://www.archive.org/download/sample_book/page/leaf12.jpg')
    expect(leaf.small_url).to eq('https://www.archive.org/download/sample_book/page/leaf12_small.jpg')
  end

  it 'builds an Internet Archive IIIF info URL' do
    expect(leaf.iiif_image_info_url).to eq('https://iiif.archive.org/iiif/sample_book$12/info.json')
  end
end
