require 'spec_helper'

describe "Zip Export README" do
  let(:readme_path) { File.join(Rails.root, 'doc', 'zip', 'README') }

  it "has the correct README file" do
    expect(File.exist?(readme_path)).to be true
  end

  it "contains documentation for all major export formats" do
    readme_content = File.read(readme_path)
    
    # Check for HTML formats
    expect(readme_content).to include('HTML FORMATS')
    expect(readme_content).to include('full -- Full text of the transcription')
    expect(readme_content).to include('text -- Just the full text')
    expect(readme_content).to include('transcript -- HTML transcript files')
    expect(readme_content).to include('translation -- HTML translation files')
    
    # Check for plaintext formats
    expect(readme_content).to include('PLAINTEXT FORMATS')
    expect(readme_content).to include('verbatim -- Full text of the transcription')
    expect(readme_content).to include('searchable -- Text optimized for full-text search')
    expect(readme_content).to include('expanded -- Expanded transcripts and translations')
    
    # Check for TEI XML
    expect(readme_content).to include('TEI XML FORMATS')
    expect(readme_content).to include('tei -- TEI-XML exports follow the TEI Consortium Guidelines')
    
    # Check for PDF formats
    expect(readme_content).to include('PDF FORMATS')
    expect(readme_content).to include('text_pdf -- PDF file containing text transcripts, work metadata, and contributor attribution')
    expect(readme_content).to include('text_only_pdf -- PDF file containing text transcripts only')
    expect(readme_content).to include('facing_edition_pdf -- PDF file with images and transcripts')
    
    # Check for document formats
    expect(readme_content).to include('DOCUMENT FORMATS')
    expect(readme_content).to include('text_docx -- Microsoft Word (.docx) file')
    
    # Check for CSV formats
    expect(readme_content).to include('CSV DATA FORMATS')
    expect(readme_content).to include('fields_and_tables -- Spreadsheet with field-based')
    expect(readme_content).to include('subject_index -- Spreadsheet listing each place a subject')
    expect(readme_content).to include('subject_details -- Spreadsheet listing each subject')
    expect(readme_content).to include('work_metadata -- Spreadsheet with a row for each work')
    expect(readme_content).to include('collection_notes -- Spreadsheet listing each note')
    
    # Check for static site
    expect(readme_content).to include('STATIC SITE')
    expect(readme_content).to include('site -- Complete static Jekyll website')
    
    # Check for organization note
    expect(readme_content).to include('Files may be organized either by work')
  end

  it "has improved structure compared to original" do
    readme_content = File.read(readme_path)
    
    # Should have clear section headers
    expect(readme_content).to include('FromThePage Export Formats')
    expect(readme_content).to include('FORMATS:')
    
    # Should be more comprehensive than the original
    expect(readme_content.length).to be > 500  # Original was only ~300 chars
  end
end