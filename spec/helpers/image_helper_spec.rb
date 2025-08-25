require 'spec_helper'

describe ImageHelper do
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
        expect(result[:dpi]).to be_in([ 72, 150, 300 ])
      end

      it 'calculates DPI correctly' do
        result = ImageHelper.calculate_page_size_and_dpi(test_pdf_with_spaces)

        expect(result[:raw_page_size]).not_to be_empty
        expect(result[:dpi]).to be_in([ 72, 150, 300 ])

        # Test that the DPI calculation logic works correctly
        raw_page_size = result[:raw_page_size]
        dpi = 300
        pixel_dim = raw_page_size.split(' x ').map { |e| e.to_f / 72 * dpi }

        expect(pixel_dim).to be_an(Array)
        expect(pixel_dim.length).to eq(2)
        expect(pixel_dim[0]).to be > 0
        expect(pixel_dim[1]).to be > 0

        # Verify the DPI reduction logic matches the result
        if pixel_dim.max >= 16000
          dpi = 150
          pixel_dim = raw_page_size.split(' x ').map { |e| e.to_f / 72 * dpi }
          if pixel_dim.max >= 16000
            dpi = 72
          end
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
        expect(result[:dpi]).to be_in([ 72, 150, 300 ])
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
        expect(result[:dpi]).to be_in([ 72, 150, 300 ])
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
end
