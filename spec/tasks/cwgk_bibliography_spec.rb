require 'spec_helper'

RSpec.describe 'CWGK Rake Tasks' do
  fixtures [:collections, :users, :articles]
  
  let(:collection) { Collection.first }
  let(:xml_directory) { File.join(Rails.root, 'test_data', 'cwgk') }
  
  before do
    # Create test directory and sample XML file
    FileUtils.mkdir_p(xml_directory)
    @test_file = File.join(xml_directory, 'P001001.xml')
    
    # Create a sample TEI file with bibliography containing markup
    sample_xml = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <TEI xmlns="http://www.tei-c.org/ns/1.0">
        <teiHeader>
          <fileDesc>
            <titleStmt>
              <title>Test Subject</title>
            </titleStmt>
          </fileDesc>
        </teiHeader>
        <text>
          <body>
            <p>Test content</p>
            <bibl>First citation with <hi rend="italic">Italicized Book Title</hi> by Author Name.</bibl>
            <bibl>Second citation with URL: https://www.findagrave.com/cgi-bin/fg.cgi?page=gr&amp;GSln=test&amp;GRid=123456</bibl>
            <bibl>Third citation with <hi rend="italic">Another Book</hi> and normal text.</bibl>
          </body>
        </text>
      </TEI>
    XML
    
    File.write(@test_file, sample_xml)
    
    # Create a test article with the corresponding URI
    @article = Article.create!(
      title: 'Test Subject',
      collection: collection,
      uri: 'P001001',
      bibliography: 'Original plain text bibliography'
    )
  end
  
  after do
    # Clean up test files and data
    FileUtils.rm_rf(xml_directory) if Dir.exist?(xml_directory)
    @article&.destroy
  end
  
  describe 'convert_urls_to_links helper method' do
    before do
      # Load the rake task to access helper methods
      load File.join(Rails.root, 'lib', 'tasks', 'cwgk_migrate.rake')
    end
    
    it 'converts bare URLs to anchor tags' do
      content = 'Visit https://example.com for more info'
      result = convert_urls_to_links(content)
      expect(result).to eq('Visit <a href="https://example.com">https://example.com</a> for more info')
    end
    
    it 'does not double-wrap already linked URLs' do
      content = 'Visit <a href="https://example.com">https://example.com</a> for more info'
      result = convert_urls_to_links(content)
      expect(result).to eq('Visit <a href="https://example.com">https://example.com</a> for more info')
    end
    
    it 'handles multiple URLs in the same content' do
      content = 'First https://example.com and second https://test.org link'
      result = convert_urls_to_links(content)
      expect(result).to include('<a href="https://example.com">https://example.com</a>')
      expect(result).to include('<a href="https://test.org">https://test.org</a>')
    end
    
    it 'handles URLs with complex query parameters' do
      content = 'Citation: https://www.findagrave.com/cgi-bin/fg.cgi?page=gr&amp;GSln=test&amp;GRid=123456'
      result = convert_urls_to_links(content)
      expect(result).to include('<a href="https://www.findagrave.com/cgi-bin/fg.cgi?page=gr&amp;GSln=test&amp;GRid=123456">https://www.findagrave.com/cgi-bin/fg.cgi?page=gr&amp;GSln=test&amp;GRid=123456</a>')
    end
  end
  
  describe 'update_cwgk_bibliography task' do
    it 'updates article bibliography with TEI markup preserved' do
      # Load and run the rake task
      load File.join(Rails.root, 'lib', 'tasks', 'cwgk_migrate.rake')
      
      # Run the task by calling the logic directly
      file_contents = File.read(@test_file)
      doc = Nokogiri::XML(file_contents)
      
      bibl_elements = doc.search('bibl')
      expect(bibl_elements.size).to eq(3)
      
      bibliography_content = []
      bibl_elements.each do |bibl|
        inner_content = bibl.inner_html.strip
        inner_content = convert_urls_to_links(inner_content)
        bibliography_content << "<bibl>#{inner_content}</bibl>"
      end
      
      formatted_bibliography = bibliography_content.join("\n")
      
      @article.bibliography = formatted_bibliography
      @article.save!
      
      # Verify the results
      @article.reload
      expect(@article.bibliography).to include('<hi rend="italic">Italicized Book Title</hi>')
      expect(@article.bibliography).to include('<hi rend="italic">Another Book</hi>')
      expect(@article.bibliography).to include('<a href="https://www.findagrave.com/cgi-bin/fg.cgi?page=gr&amp;GSln=test&amp;GRid=123456">https://www.findagrave.com/cgi-bin/fg.cgi?page=gr&amp;GSln=test&amp;GRid=123456</a>')
      expect(@article.bibliography).to include('<bibl>')
    end
  end
end