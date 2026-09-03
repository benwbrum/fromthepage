require 'spec_helper'

RSpec.describe IaWork, type: :model do
  describe 'description length' do
    it 'matches the maximum length accepted by Work' do
      ia_work_maximum = described_class.validators_on(:description).filter_map do |validator|
        validator.options[:maximum] if validator.is_a?(ActiveModel::Validations::LengthValidator)
      end
      work_maximum = Work.validators_on(:description).filter_map do |validator|
        validator.options[:maximum] if validator.is_a?(ActiveModel::Validations::LengthValidator)
      end

      expect(ia_work_maximum).to include(described_class::DESCRIPTION_MAX_LENGTH)
      expect(ia_work_maximum).to eq(work_maximum)
    end
  end

  describe '#archive_download_url' do
    it 'puts the identifier and derivative filename in separately encoded path segments' do
      work = described_class.new(book_id: 'book id')

      expect(work.archive_download_url('scan data/01 #1.xml')).to eq(
        'https://archive.org/download/book%20id/scan%20data%2F01%20%231.xml'
      )
    end

    it 'encodes spaces as complete percent escapes accepted by URI parsing' do
      work = described_class.new(book_id: 'ms-500-full')

      url = work.archive_download_url('MS500 Full_scandata.xml')

      expect(url).to eq('https://archive.org/download/ms-500-full/MS500%20Full_scandata.xml')
      expect { URI.parse(url) }.not_to raise_error
    end
  end

  describe '#ingest_work' do
    it 'fetches scandata and DjVu XML through redirecting archive.org download URLs' do
      identifier = 'redirected-book'
      location_url = "http://www.archive.org/services/find_file.php?file=#{identifier}"
      scandata_url = "https://archive.org/download/#{identifier}/scan%20data%2F01_scandata.xml"
      djvu_url = "https://archive.org/download/#{identifier}/ocr%20files%2F01_djvu.xml"
      location_document = <<~XML
        <root>
          <results server="ia111111.us.archive.org" dir="/old/items/#{identifier}" />
          <identifier>#{identifier}</identifier>
          <title>Redirected Book</title>
          <imagecount>1</imagecount>
          <file name="scan data/01_scandata.xml"><format>Scandata</format></file>
          <file name="ocr files/01_djvu.xml"><format>Djvu XML</format></file>
          <file name="#{identifier}_jp2.zip"><format>Single Page Processed JP2 ZIP</format></file>
        </root>
      XML
      scandata_document = <<~XML
        <book><pageData><page leafNum="0"><pageNumber>1</pageNumber><pageType>Normal</pageType><cropBox><w>100</w><h>200</h></cropBox></page></pageData></book>
      XML
      djvu_document = <<~XML
        <DJVUXML><BODY><OBJECT><PARAM name="PAGE" value="page_0000.djvu"/><PARAGRAPH><LINE><WORD>Redirected</WORD></LINE></PARAGRAPH></OBJECT></BODY></DJVUXML>
      XML

      stub_request(:get, location_url).to_return(body: location_document)
      stub_request(:get, scandata_url).to_return(
        status: 302,
        headers: { 'Location' => 'https://ia999999.us.archive.org/new/scandata.xml' }
      )
      stub_request(:get, 'https://ia999999.us.archive.org/new/scandata.xml').to_return(body: scandata_document)
      stub_request(:get, djvu_url).to_return(
        status: 302,
        headers: { 'Location' => 'https://ia888888.us.archive.org/moved/djvu.xml' }
      )
      stub_request(:get, 'https://ia888888.us.archive.org/moved/djvu.xml').to_return(body: djvu_document)

      work = described_class.new
      work.ingest_work(identifier)

      expect(a_request(:get, scandata_url)).to have_been_made.once
      expect(a_request(:get, djvu_url)).to have_been_made.once
      expect(work.ia_leaves.first.ocr_text).to eq("Redirected\n\n")
      expect(work.server).to be_nil
    end
  end

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
      work = described_class.new(title: 'a' * 1100)

      work.truncate_title

      expect(work.title.length).to eq(1028)
      expect(work.title).to end_with('...')
    end
  end
end
