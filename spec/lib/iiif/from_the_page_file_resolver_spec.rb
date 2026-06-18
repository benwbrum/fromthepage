require 'spec_helper'
require 'iiif/from_the_page_file_resolver'

RSpec.describe Riiif::FromThePageFileResolver do
  describe '#find' do
    it 'raises an argument error for ids with non-numeric characters' do
      expect { described_class.new.find('../123') }.to raise_error(ArgumentError, /Invalid characters/)
    end

    it 'finds the page and wraps its normalized base image path in a Riiif file' do
      resolver = described_class.new
      page = instance_double(Page, base_image: '/var/apps/fromthepage/public/uploads/page.jpg')
      riiif_file = instance_double('Riiif::File')

      allow(Page).to receive(:find).with(123).and_return(page)
      allow(Riiif::File).to receive(:new).with("#{Rails.root}/public//uploads/page.jpg").and_return(riiif_file)

      expect(resolver.find('123')).to eq(riiif_file)
    end
  end

  describe '#path' do
    it 'rewrites absolute public paths under Rails.root public' do
      path = described_class.new.path('/var/apps/fromthepage/public/images/page.jpg')

      expect(path).to eq("#{Rails.root}/public//images/page.jpg")
    end

    it 'leaves filenames without a public segment under Rails.root public' do
      path = described_class.new.path('images/page.jpg')

      expect(path).to eq("#{Rails.root}/public/images/page.jpg")
    end
  end
end
