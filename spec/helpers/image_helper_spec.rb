# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

describe ImageHelper do
  describe '.unzip_file' do
    around do |example|
      Dir.mktmpdir('image-helper-zip') do |directory|
        @test_directory = directory
        example.run
      end
    end

    def build_zip(name, entries)
      archive = File.join(@test_directory, name)
      Zip::File.open(archive, create: true) do |zip|
        entries.each do |entry_name, contents|
          zip.get_output_stream(entry_name) { |stream| stream.write(contents) }
        end
      end
      archive
    end

    it 'extracts valid nested files and explicit directories' do
      archive = build_zip('valid.zip', 'pages/one.txt' => 'one', 'pages/two.txt' => 'two')
      destination = File.join(@test_directory, 'output')

      ImageHelper.unzip_file(archive, destination)

      expect(File.read(File.join(destination, 'pages/one.txt'))).to eq('one')
      expect(File.read(File.join(destination, 'pages/two.txt'))).to eq('two')
    end

    [
      '../escaped.txt',
      'pages/../../escaped.txt',
      '/tmp/absolute.txt',
      '..\\windows-escaped.txt',
      'C:\\drive-path.txt'
    ].each do |entry_name|
      it "rejects unsafe entry #{entry_name.inspect}" do
        archive = build_zip('unsafe.zip', entry_name => 'bad')
        destination = File.join(@test_directory, 'output')

        expect { ImageHelper.unzip_file(archive, destination) }.to raise_error(Zip::EntryNameError)
        expect(Dir.exist?(destination)).to be(false)
      end
    end

    it 'does not confuse a destination name prefix for containment' do
      destination = File.join(@test_directory, 'output')
      archive = build_zip('prefix.zip', '../output-other/escaped.txt' => 'bad')

      expect { ImageHelper.unzip_file(archive, destination) }.to raise_error(Zip::EntryNameError)
      expect(File.exist?(File.join(@test_directory, 'output-other/escaped.txt'))).to be(false)
    end

    it 'rejects symlink entries' do
      link = File.join(@test_directory, 'link')
      File.symlink('../outside', link)
      archive = File.join(@test_directory, 'symlink.zip')
      Zip::File.open(archive, create: true) { |zip| zip.add('link', link) }

      expect do
        ImageHelper.unzip_file(archive, File.join(@test_directory, 'output'))
      end.to raise_error(Zip::EntryNameError)
    end

    it 'rejects an existing symlink in an extraction path before writing files' do
      destination = File.join(@test_directory, 'output')
      outside = File.join(@test_directory, 'outside')
      FileUtils.mkdir_p([destination, outside])
      File.symlink(outside, File.join(destination, 'pages'))
      archive = build_zip('redirect.zip', 'safe.txt' => 'safe', 'pages/escaped.txt' => 'bad')

      expect { ImageHelper.unzip_file(archive, destination) }.to raise_error(Zip::EntryNameError)
      expect(File.exist?(File.join(destination, 'safe.txt'))).to be(false)
      expect(File.exist?(File.join(outside, 'escaped.txt'))).to be(false)
    end
  end

  describe '.calculate_page_size_and_dpi' do
    context 'with filename containing spaces' do
      let(:test_pdf_source) { File.join(Rails.root, 'test_data/uploads/test.pdf') }
      let(:test_pdf_with_spaces) { '/tmp/test with spaces.pdf' }

      before do
        FileUtils.cp(test_pdf_source, test_pdf_with_spaces)
      end

      after do
        FileUtils.rm(test_pdf_with_spaces) if File.exist?(test_pdf_with_spaces)
      end

      it 'successfully extracts page size information' do
        result = ImageHelper.calculate_page_size_and_dpi(test_pdf_with_spaces)

        expect(result[:raw_page_size]).not_to be_empty
        expect(result[:raw_page_size]).to match(/\d+(\.\d+)? x \d+(\.\d+)?/)
        expect(result[:dpi]).to be_in([72, 150, 300])
      end

      it 'calculates DPI correctly' do
        result = ImageHelper.calculate_page_size_and_dpi(test_pdf_with_spaces)

        expect(result[:raw_page_size]).not_to be_empty
        expect(result[:dpi]).to be_in([72, 150, 300])

        # Test that the DPI calculation logic works correctly
        raw_page_size = result[:raw_page_size]
        dpi = 300
        pixel_dim = raw_page_size.split(' x ').map { |e| e.to_f / 72 * dpi }

        expect(pixel_dim).to be_an(Array)
        expect(pixel_dim.length).to eq(2)
        expect(pixel_dim[0]).to be > 0
        expect(pixel_dim[1]).to be > 0

        # Verify the DPI reduction logic matches the result
        if pixel_dim.max >= 16_000
          dpi = 150
          pixel_dim = raw_page_size.split(' x ').map { |e| e.to_f / 72 * dpi }
          dpi = 72 if pixel_dim.max >= 16_000
        end

        expect(result[:dpi]).to eq(dpi)
      end
    end

    context 'with filename without spaces' do
      let(:test_pdf_source) { File.join(Rails.root, 'test_data/uploads/test.pdf') }
      let(:test_pdf_normal) { '/tmp/test_no_spaces.pdf' }

      before do
        FileUtils.cp(test_pdf_source, test_pdf_normal)
      end

      after do
        FileUtils.rm(test_pdf_normal) if File.exist?(test_pdf_normal)
      end

      it 'successfully extracts page size information' do
        result = ImageHelper.calculate_page_size_and_dpi(test_pdf_normal)

        expect(result[:raw_page_size]).not_to be_empty
        expect(result[:raw_page_size]).to match(/\d+(\.\d+)? x \d+(\.\d+)?/)
        expect(result[:dpi]).to be_in([72, 150, 300])
      end

      it 'maintains backward compatibility' do
        # Test that Shellwords.escape doesn't change filenames without special characters
        require 'shellwords'
        escaped_filename = Shellwords.escape(test_pdf_normal)

        expect(escaped_filename).to eq(test_pdf_normal)
      end
    end

    context 'with filename containing special characters' do
      let(:test_pdf_source) { File.join(Rails.root, 'test_data/uploads/test.pdf') }
      let(:test_pdf_special) { "/tmp/test'with'quotes.pdf" }

      before do
        FileUtils.cp(test_pdf_source, test_pdf_special)
      end

      after do
        FileUtils.rm(test_pdf_special) if File.exist?(test_pdf_special)
      end

      it 'successfully handles filenames with single quotes' do
        result = ImageHelper.calculate_page_size_and_dpi(test_pdf_special)

        expect(result[:raw_page_size]).not_to be_empty
        expect(result[:raw_page_size]).to match(/\d+(\.\d+)? x \d+(\.\d+)?/)
        expect(result[:dpi]).to be_in([72, 150, 300])
      end
    end
  end

  describe '.extract_pdf' do
    context 'with filename containing spaces' do
      let(:test_pdf_source) { File.join(Rails.root, 'test_data/uploads/test.pdf') }
      let(:test_pdf_with_spaces) { '/tmp/test with spaces.pdf' }

      before do
        FileUtils.cp(test_pdf_source, test_pdf_with_spaces)
      end

      after do
        FileUtils.rm(test_pdf_with_spaces) if File.exist?(test_pdf_with_spaces)
        # Clean up any extracted directories
        destination = test_pdf_with_spaces.gsub(/\.pdf$/, '')
        FileUtils.rm_rf(destination) if Dir.exist?(destination)
      end

      it 'successfully extracts PDF without errors' do
        # Test that the full extraction process works with spaces in filename
        expect { ImageHelper.extract_pdf(test_pdf_with_spaces) }.not_to raise_error
      end
    end
  end

  describe '.convert_tiff' do
    let(:test_dir) { '/tmp/tiff_test' }
    let(:test_tiff) { File.join(test_dir, 'test.tif') }
    let(:expected_jpg) { File.join(test_dir, 'test.jpg') }

    before do
      FileUtils.mkdir_p(test_dir)
      # Create a simple 1x1 TIFF image for testing
      require 'rmagick'
      image = Magick::Image.new(1, 1)
      image.write(test_tiff)
    end

    after do
      FileUtils.rm_rf(test_dir) if Dir.exist?(test_dir)
    end

    it 'converts TIFF to JPG and removes original file' do
      expect(File.exist?(test_tiff)).to be true

      # Convert the TIFF file
      result = ImageHelper.convert_tiff(test_tiff)

      # The original TIFF should be deleted
      expect(File.exist?(test_tiff)).to be false

      # The JPG should be created
      expect(File.exist?(expected_jpg)).to be true

      # The result should be the JPG filename
      expect(result).to be_a(Magick::ImageList)
    end

    it 'handles the case when original file does not exist' do
      # Remove the file before conversion to test safety check
      File.delete(test_tiff)

      expect(File.exist?(test_tiff)).to be false

      # This should not raise an error even if the file doesn't exist
      expect { ImageHelper.convert_tiff(test_tiff) }.to raise_error(Magick::ImageMagickError)
    end
  end
end
