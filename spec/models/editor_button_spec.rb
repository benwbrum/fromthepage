require 'spec_helper'

RSpec.describe EditorButton, type: :model do
  describe 'tag helpers' do
    it 'uses TEI tags by default' do
      button = described_class.new(key: described_class::Keys::BOLD, prefer_html: false)

      expect(button.open_tag).to eq('<hi rend="bold">')
      expect(button.close_tag).to eq('</hi>')
    end

    it 'uses HTML tags when preferred and available' do
      button = described_class.new(key: described_class::Keys::BOLD, prefer_html: true)

      expect(button.open_tag).to eq('<b>')
      expect(button.close_tag).to eq('</b>')
    end

    it 'detects attributes in opening tags' do
      button = described_class.new(key: described_class::Keys::DATE)

      expect(button.has_attribute).to be_present
    end

    it 'sets the cursor offset to the close tag length' do
      button = described_class.new(key: described_class::Keys::ITALIC, prefer_html: true)

      expect(button.cursor_offset).to eq(button.close_tag.length)
    end

    it 'returns the editor hotkey' do
      expect(described_class.new.hotkey).to eq('Ctrl-E')
    end
  end
end
