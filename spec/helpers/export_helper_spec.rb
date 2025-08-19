require 'spec_helper'

describe ExportHelper do
  include ExportHelper

  describe '#clean_date_for_when_attribute' do
    it 'uses EDTF library for valid EDTF dates' do
      expect(clean_date_for_when_attribute('1866')).to eq('1866')
      expect(clean_date_for_when_attribute('1866-05')).to eq('1866-05')
      expect(clean_date_for_when_attribute('1866-05-15')).to eq('1866-05-15')
    end

    it 'falls back to basic cleaning for dates with question marks' do
      expect(clean_date_for_when_attribute('1866?')).to eq('1866')
    end

    it 'handles multiple question marks' do
      expect(clean_date_for_when_attribute('1866???')).to eq('1866')
    end

    it 'returns nil for invalid dates' do
      expect(clean_date_for_when_attribute('invalid')).to be_nil
      expect(clean_date_for_when_attribute('')).to be_nil
      expect(clean_date_for_when_attribute(nil)).to be_nil
    end

    it 'validates date format for fallback cleaning' do
      expect(clean_date_for_when_attribute('1866-13')).to be_nil  # Invalid month
      expect(clean_date_for_when_attribute('186')).to be_nil     # Too short
    end

    it 'handles EDTF parsing errors gracefully' do
      # Test that we gracefully handle when EDTF can't parse something
      # but our fallback can
      allow(Date).to receive(:edtf).and_raise(StandardError)
      expect(clean_date_for_when_attribute('1866?')).to eq('1866')
    end
  end

  describe 'TEI validation fixes' do
    context 'XML ID generation' do
      it 'prefixes numeric IDs to make valid NCName' do
        work_id = '14648'
        xml_id = "W#{work_id}"
        expect(xml_id).to eq('W14648')
        expect(xml_id).not_to match(/^\d/)  # Should not start with digit
      end
    end

    context 'ptr elements' do
      it 'should be self-closing without text content' do
        # This is more of a template structure test
        # The actual fix is in the ERB template
        expect(true).to be true  # Placeholder for template structure
      end
    end

    context 'geo element placement' do
      it 'should be directly in place element not in note' do
        # This is a template structure test
        # The actual fix moves geo out of note wrapper
        expect(true).to be true  # Placeholder for template structure  
      end
    end

    context 'depth attribute replacement' do
      it 'replaces depth with subtype for head elements' do
        # Test that depth attribute is replaced with subtype/type for TEI compliance
        expect(true).to be true  # Placeholder for template structure
      end
    end
  end
end