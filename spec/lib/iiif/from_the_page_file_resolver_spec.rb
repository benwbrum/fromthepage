require 'spec_helper'
require 'iiif/from_the_page_file_resolver'

RSpec.describe Riiif::FromThePageFileResolver do
  describe '#find' do
    it 'raises an argument error for ids with non-numeric characters' do
      expect { described_class.new.find('../123') }.to raise_error(ArgumentError, /Invalid characters/)
    end

    context 'when page has a legacy base_image path' do
      it 'finds the page and wraps its normalized base image path in a Riiif file' do
        resolver = described_class.new
        page = instance_double(Page, base_image: '/var/apps/fromthepage/public/uploads/page.jpg', image: double(attached?: false))
        riiif_file = instance_double('Riiif::File')

        allow(Page).to receive(:find).with(123).and_return(page)
        allow(Riiif::File).to receive(:new).with("#{Rails.root}/public//uploads/page.jpg").and_return(riiif_file)

        expect(resolver.find('123')).to eq(riiif_file)
      end

      it 'raises ImageNotFoundError when base_image is blank and no attachment' do
        resolver = described_class.new
        page = instance_double(Page, base_image: '', image: double(attached?: false))

        allow(Page).to receive(:find).with(456).and_return(page)

        expect { resolver.find('456') }.to raise_error(Riiif::ImageNotFoundError)
      end
    end

    context 'when page has an Active Storage image on disk service' do
      it 'returns a Riiif::File using the disk service path' do
        resolver = described_class.new
        disk_service = double('DiskService', path_for: '/storage/ab/c1/abc123')
        blob = instance_double(ActiveStorage::Blob, key: 'abc123', service: disk_service)
        image_attachment = double(attached?: true, blob: blob)
        page = instance_double(Page, image: image_attachment)
        riiif_file = instance_double('Riiif::File')

        allow(Page).to receive(:find).with(789).and_return(page)
        allow(Riiif::File).to receive(:new).with('/storage/ab/c1/abc123').and_return(riiif_file)

        expect(resolver.find('789')).to eq(riiif_file)
      end
    end

    context 'when page has an Active Storage image on a non-disk service (e.g. S3)' do
      it 'downloads the blob to a temp cache and returns a Riiif::File' do
        resolver = described_class.new
        s3_service = instance_double(ActiveStorage::Service)
        filename = instance_double(ActiveStorage::Filename, extension_with_delimiter: '.jpg')
        blob = instance_double(ActiveStorage::Blob, key: 'xyz987', service: s3_service, filename: filename)
        tmp_file = Tempfile.new(['blob', '.jpg'])
        image_attachment = double(attached?: true, blob: blob)
        page = instance_double(Page, image: image_attachment)
        riiif_file = instance_double('Riiif::File')

        allow(Page).to receive(:find).with(999).and_return(page)
        allow(blob).to receive(:open).and_yield(tmp_file)

        expected_cache_path = Rails.root.join('tmp', 'riiif_cache', 'xyz987.jpg').to_s
        allow(Riiif::File).to receive(:new).with(expected_cache_path).and_return(riiif_file)

        # Ensure cached file doesn't exist before the test
        FileUtils.rm_f(expected_cache_path)

        result = resolver.find('999')
        expect(result).to eq(riiif_file)
        expect(File.exist?(expected_cache_path)).to be true
      ensure
        FileUtils.rm_f(Rails.root.join('tmp', 'riiif_cache', 'xyz987.jpg').to_s)
        tmp_file.close
        tmp_file.unlink
      end
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
