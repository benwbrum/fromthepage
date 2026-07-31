require 'spec_helper'
require 'rake'

describe 'Fix field label dashes rake task' do
  before(:all) do
    Rake.application = Rake::Application.new
    Rails.application.load_tasks
  end

  before(:each) do
    Rake::Task['fromthepage:fix_field_label_dashes'].reenable
  end

  describe 'fromthepage:fix_field_label_dashes' do
    let(:collection) { create(:collection, :field_based, works: []) }
    let(:work) { create(:work, collection: collection) }
    let(:field) do
      create(:transcription_field, :text_field, collection: collection, label: 'Drawing No.', position: 1)
    end

    let!(:page) do
      p = create(:page, work: work)
      p.transcription_json = { field.id.to_s => '171,479' }
      # Reproduces exactly what the pre-fix TranscriptionField::Lib::Utils.parse_fields
      # wrote: the parameterized form key ("drawing-no") instead of field.label.
      p.source_text = '<span class="field__label">drawing-no: </span>171,479' + "\n\n"
      p.save!
      p
    end

    before do
      field
      # Sanity check that our setup reproduces the real bug before testing the fix.
      expect(page.xml_text).to include('drawing-no')
    end

    let(:broken_xml_text) { page.xml_text }

    it 'reports the change without writing anything in dry_run mode (default)' do
      output = capture_stdout do
        Rake::Task['fromthepage:fix_field_label_dashes'].invoke
      end

      expect(output).to include("Page #{page.id}")
      expect(output).to include('would change')

      page.reload
      expect(page.xml_text).to eq(broken_xml_text)
    end

    it 'rewrites xml_text with the real field label when dry_run=false, without creating a page_version or touching source_text' do
      original_source_text = page.source_text
      version_count_before = PageVersion.where(page: page).count

      ENV['dry_run'] = 'false'
      ENV['page_id'] = page.id.to_s
      capture_stdout do
        Rake::Task['fromthepage:fix_field_label_dashes'].invoke
      end
      ENV.delete('dry_run')
      ENV.delete('page_id')

      page.reload
      expect(page.xml_text).to include('Drawing No.: ')
      expect(page.xml_text).not_to include('drawing-no')
      expect(page.source_text).to eq(original_source_text)
      expect(PageVersion.where(page: page).count).to eq(version_count_before)
    end

    it 'does not touch pages updated before the bug was introduced' do
      page.update_column(:updated_at, Time.zone.parse('2025-11-01T00:00:00Z'))

      ENV['dry_run'] = 'false'
      capture_stdout do
        Rake::Task['fromthepage:fix_field_label_dashes'].invoke
      end
      ENV.delete('dry_run')

      page.reload
      expect(page.xml_text).to eq(broken_xml_text)
    end
  end

  def capture_stdout(&block)
    original_stdout = $stdout
    $stdout = StringIO.new
    block.call
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
