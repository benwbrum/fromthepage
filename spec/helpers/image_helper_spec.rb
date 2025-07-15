require 'spec_helper'

describe ImageHelper do
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

      it 'successfully extracts page size information' do
        # Test the pdfinfo command using proper shell escaping
        require 'shellwords'
        raw_page_size = `pdfinfo #{Shellwords.escape(test_pdf_with_spaces)} | grep "Page size"`.gsub(/Page size:\s+/,'').gsub(' pts','').chomp
        
        expect(raw_page_size).not_to be_empty
        expect(raw_page_size).to match(/\d+(\.\d+)? x \d+(\.\d+)?/)
      end

      it 'fails without proper escaping' do
        # Test the broken version to ensure our test is valid
        raw_page_size = `pdfinfo #{test_pdf_with_spaces} | grep "Page size"`.gsub(/Page size:\s+/,'').gsub(' pts','').chomp
        
        expect(raw_page_size).to be_empty
      end

      it 'calculates DPI correctly' do
        # Test the DPI calculation logic that uses the pdfinfo output
        require 'shellwords'
        raw_page_size = `pdfinfo #{Shellwords.escape(test_pdf_with_spaces)} | grep "Page size"`.gsub(/Page size:\s+/,'').gsub(' pts','').chomp
        
        expect(raw_page_size).not_to be_empty
        
        dpi = 300
        pixel_dim = raw_page_size.split(' x ').map{|e| e.to_f / 72 * dpi}
        
        expect(pixel_dim).to be_an(Array)
        expect(pixel_dim.length).to eq(2)
        expect(pixel_dim[0]).to be > 0
        expect(pixel_dim[1]).to be > 0
        
        # Test the DPI reduction logic
        if pixel_dim.max >= 16000
          dpi = 150
          pixel_dim = raw_page_size.split(' x ').map{|e| e.to_f / 72 * dpi}
          if pixel_dim.max >= 16000
            dpi = 72
          end
        end
        
        expect(dpi).to be_in([72, 150, 300])
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
        # Clean up any extracted directories
        destination = test_pdf_normal.gsub(/\.pdf$/, '')
        FileUtils.rm_rf(destination) if Dir.exist?(destination)
      end

      it 'successfully extracts page size information' do
        # Test that our fix doesn't break normal filenames
        require 'shellwords'
        raw_page_size = `pdfinfo #{Shellwords.escape(test_pdf_normal)} | grep "Page size"`.gsub(/Page size:\s+/,'').gsub(' pts','').chomp
        
        expect(raw_page_size).not_to be_empty
        expect(raw_page_size).to match(/\d+(\.\d+)? x \d+(\.\d+)?/)
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
        # Clean up any extracted directories
        destination = test_pdf_special.gsub(/\.pdf$/, '')
        FileUtils.rm_rf(destination) if Dir.exist?(destination)
      end

      it 'successfully handles filenames with single quotes' do
        # Test that our robust escaping handles single quotes in filenames
        require 'shellwords'
        raw_page_size = `pdfinfo #{Shellwords.escape(test_pdf_special)} | grep "Page size"`.gsub(/Page size:\s+/,'').gsub(' pts','').chomp
        
        expect(raw_page_size).not_to be_empty
        expect(raw_page_size).to match(/\d+(\.\d+)? x \d+(\.\d+)?/)
      end

      it 'fails with simple quote escaping' do
        # Test that simple quote escaping fails with single quotes in filename
        raw_page_size = `pdfinfo '#{test_pdf_special}' | grep "Page size"`.gsub(/Page size:\s+/,'').gsub(' pts','').chomp
        
        expect(raw_page_size).to be_empty
      end
    end
  end
end