require 'spec_helper'

RSpec.describe IaWork, type: :model do
  describe '#zip_file' do
    it 'uses the conventional archive name when no explicit zip file is stored' do
      work = described_class.new(book_id: 'book', image_format: 'jp2', archive_format: 'zip')

      expect(work.zip_file).to eq('book_jp2.zip')
    end

    it 'returns an explicit zip file when present' do
      work = described_class.new(zip_file: 'custom.zip')

      expect(work.zip_file).to eq('custom.zip')
    end
  end

  describe '#book_path and #sub_prefix' do
    it 'uses the IA path and book id without scandata metadata' do
      work = described_class.new(book_id: 'book', ia_path: '/items/book')

      expect(work.book_path).to eq('/items/book')
      expect(work.sub_prefix).to eq('book')
    end

    it 'uses the IA path and book id when scandata matches the book id' do
      work = described_class.new(book_id: 'book', ia_path: '/items/book', scandata_file: 'book_scandata.xml')

      expect(work.book_path).to eq('/items/book')
      expect(work.sub_prefix).to eq('book')
    end

    it 'uses the scandata stub when it differs from the book id' do
      work = described_class.new(book_id: 'book', ia_path: '/items/book', scandata_file: 'volume1_scandata.xml')

      expect(work.book_path).to eq('/items/book/volume1')
      expect(work.sub_prefix).to eq('volume1')
    end
  end

  describe '#truncate_title' do
    it 'truncates titles to the database limit' do
      work = described_class.new(title: 'a' * 300)

      work.truncate_title

      expect(work.title.length).to eq(255)
      expect(work.title).to end_with('...')
    end
  end
end
