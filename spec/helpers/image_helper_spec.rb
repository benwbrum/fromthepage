# frozen_string_literal: true

require 'spec_helper'

describe ImageHelper do
  describe '.sanitize_filename' do
    it 'replaces spaces with underscores' do
      expect(ImageHelper.sanitize_filename('my file with spaces.pdf')).to eq('my_file_with_spaces.pdf')
    end

    it 'preserves the file extension' do
      expect(ImageHelper.sanitize_filename('my file.PDF')).to eq('my_file.PDF')
      expect(ImageHelper.sanitize_filename('archive file.zip')).to eq('archive_file.zip')
    end

    it 'does not modify filenames without spaces' do
      expect(ImageHelper.sanitize_filename('clean_filename.pdf')).to eq('clean_filename.pdf')
    end

    it 'replaces multiple consecutive spaces with a single underscore' do
      expect(ImageHelper.sanitize_filename('too  many   spaces.pdf')).to eq('too_many_spaces.pdf')
    end

    it 'truncates base names longer than 100 characters' do
      long_name = ('a' * 150) + '.pdf'
      result = ImageHelper.sanitize_filename(long_name)
      expect(File.basename(result, '.pdf').length).to eq(100)
      expect(File.extname(result)).to eq('.pdf')
    end

    it 'does not truncate base names exactly 100 characters long' do
      name = ('a' * 100) + '.pdf'
      result = ImageHelper.sanitize_filename(name)
      expect(File.basename(result, '.pdf').length).to eq(100)
    end

    it 'replaces special characters with underscores' do
      expect(ImageHelper.sanitize_filename("file(1).pdf")).to eq('file_1_.pdf')
    end

    it 'replaces apostrophes and commas to produce a shell-safe filename' do
      # Apostrophes break shell single-quoted strings used in the Ghostscript command
      expect(ImageHelper.sanitize_filename("1850-1910_Town_Clerk's_Miscellaneous_Records,_Book_1.pdf"))
        .to eq('1850-1910_Town_Clerk_s_Miscellaneous_Records__Book_1.pdf')
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

  describe '.unzip_file' do
    let(:test_dir) { '/tmp/zip_permission_test' }
    let(:zip_file_path) { File.join(test_dir, 'test_restricted_perms.zip') }
    let(:extraction_path) { File.join(test_dir, 'extracted') }
    let(:source_dir) { File.join(test_dir, 'source') }
    let(:restricted_dir) { File.join(source_dir, 'restricted_folder') }
    let(:test_file) { File.join(restricted_dir, 'test_image.jpg') }

    before do
      require 'zip'
      FileUtils.mkdir_p(test_dir)
      FileUtils.mkdir_p(restricted_dir)

      # Create a test image file
      require 'rmagick'
      image = Magick::Image.new(10, 10)
      image.write(test_file)

      # Create a zip file with restricted directory permissions
      Zip::File.open(zip_file_path, create: true) do |zipfile|
        # Add the directory entry with read-only permissions
        zipfile.mkdir('restricted_folder', 0555)
        # Add the file
        zipfile.add('restricted_folder/test_image.jpg', test_file)
      end
    end

    after do
      FileUtils.rm_rf(test_dir) if Dir.exist?(test_dir)
    end

    it 'successfully extracts files from directories with restricted permissions' do
      # Extract the zip file
      expect { ImageHelper.unzip_file(zip_file_path, extraction_path) }.not_to raise_error

      # Verify the directory was created
      extracted_dir = File.join(extraction_path, 'restricted_folder')
      expect(File.directory?(extracted_dir)).to be true

      # Verify the directory has write permissions (owner can write)
      dir_mode = File.stat(extracted_dir).mode
      owner_can_write = (dir_mode & 0o200) != 0
      expect(owner_can_write).to be true

      # Verify the file was extracted
      extracted_file = File.join(extracted_dir, 'test_image.jpg')
      expect(File.exist?(extracted_file)).to be true

      # Verify we can write to the directory
      test_write_file = File.join(extracted_dir, 'test_write.txt')
      expect { File.write(test_write_file, 'test') }.not_to raise_error
      expect(File.exist?(test_write_file)).to be true
    end

    it 'handles nested directories with restricted permissions' do
      # Create a zip with nested restricted directories
      nested_zip_path = File.join(test_dir, 'nested_restricted.zip')
      nested_source = File.join(test_dir, 'nested_source')
      nested_dir1 = File.join(nested_source, 'level1')
      nested_dir2 = File.join(nested_dir1, 'level2')
      FileUtils.mkdir_p(nested_dir2)

      nested_file = File.join(nested_dir2, 'nested_image.jpg')
      image = Magick::Image.new(5, 5)
      image.write(nested_file)

      Zip::File.open(nested_zip_path, create: true) do |zipfile|
        zipfile.mkdir('level1', 0555)
        zipfile.mkdir('level1/level2', 0555)
        zipfile.add('level1/level2/nested_image.jpg', nested_file)
      end

      nested_extraction_path = File.join(test_dir, 'nested_extracted')

      # Extract and verify
      expect { ImageHelper.unzip_file(nested_zip_path, nested_extraction_path) }.not_to raise_error

      extracted_nested_file = File.join(nested_extraction_path, 'level1', 'level2', 'nested_image.jpg')
      expect(File.exist?(extracted_nested_file)).to be true

      # Verify both levels have write permissions
      level1_dir = File.join(nested_extraction_path, 'level1')
      level2_dir = File.join(level1_dir, 'level2')

      level1_mode = File.stat(level1_dir).mode
      level2_mode = File.stat(level2_dir).mode

      expect((level1_mode & 0o200) != 0).to be true
      expect((level2_mode & 0o200) != 0).to be true
    end
  end
end
