require 'spec_helper'
require 'rake'

describe 'Bulk export rake tasks' do
  before(:all) do
    Rake.application = Rake::Application.new
    Rails.application.load_tasks
  end

  describe 'fromthepage:clean_bulk_exports' do
    let(:user) { create(:user) }
    let(:collection) { create(:collection) }

    before(:each) do
      # Create the export directory if it doesn't exist
      FileUtils.mkdir_p('/tmp/fromthepage_exports')
    end

    after(:each) do
      # Clean up any remaining files
      Dir.glob('/tmp/fromthepage_exports/export_*.zip').each { |f| File.delete(f) if File.exist?(f) }
      Dir.glob('/tmp/fromthepage_exports/rake_bulk_export_*.log').each { |f| File.delete(f) if File.exist?(f) }
    end

    it 'deletes old bulk export records and their associated files' do
      # Create an old bulk export with finished status
      old_export = create(:bulk_export, :finished, 
                         user: user, 
                         collection: collection,
                         created_at: 40.days.ago)
      
      # Create the zip file and log file to simulate a real export
      FileUtils.touch(old_export.zip_file_name)
      FileUtils.touch(old_export.log_file)
      
      expect(File.exist?(old_export.zip_file_name)).to be true
      expect(File.exist?(old_export.log_file)).to be true
      expect(BulkExport.find_by(id: old_export.id)).to_not be_nil

      # Run the rake task with 30 days parameter
      Rake::Task['fromthepage:clean_bulk_exports'].reenable
      capture_stdout { Rake::Task['fromthepage:clean_bulk_exports'].invoke(30) }

      # Verify the files were deleted
      expect(File.exist?(old_export.zip_file_name)).to be false
      expect(File.exist?(old_export.log_file)).to be false
      
      # Verify the database record was deleted
      expect(BulkExport.find_by(id: old_export.id)).to be_nil
    end

    it 'does not delete recent bulk exports' do
      # Create a recent bulk export
      recent_export = create(:bulk_export, :finished,
                            user: user,
                            collection: collection,
                            created_at: 10.days.ago)
      
      # Create the zip file to simulate a real export
      FileUtils.touch(recent_export.zip_file_name)
      FileUtils.touch(recent_export.log_file)
      
      recent_export_id = recent_export.id
      
      expect(File.exist?(recent_export.zip_file_name)).to be true
      expect(File.exist?(recent_export.log_file)).to be true

      # Run the rake task with 30 days parameter
      Rake::Task['fromthepage:clean_bulk_exports'].reenable
      capture_stdout { Rake::Task['fromthepage:clean_bulk_exports'].invoke(30) }

      # Verify the files were NOT deleted
      expect(File.exist?(recent_export.zip_file_name)).to be true
      expect(File.exist?(recent_export.log_file)).to be true
      
      # Verify the database record still exists
      expect(BulkExport.find_by(id: recent_export_id)).to_not be_nil
      
      # Clean up
      File.delete(recent_export.zip_file_name) if File.exist?(recent_export.zip_file_name)
      File.delete(recent_export.log_file) if File.exist?(recent_export.log_file)
    end

    it 'handles exports where files are already missing' do
      # Create an old bulk export without creating the actual files
      old_export = create(:bulk_export, :finished,
                         user: user,
                         collection: collection,
                         created_at: 40.days.ago)
      
      # Verify files don't exist
      expect(File.exist?(old_export.zip_file_name)).to be false
      expect(File.exist?(old_export.log_file)).to be false

      # Run the rake task with 30 days parameter
      Rake::Task['fromthepage:clean_bulk_exports'].reenable
      expect {
        capture_stdout { Rake::Task['fromthepage:clean_bulk_exports'].invoke(30) }
      }.not_to raise_error
      
      # Verify the database record was still deleted
      expect(BulkExport.find_by(id: old_export.id)).to be_nil
    end

    it 'processes multiple old exports' do
      # Create multiple old bulk exports
      old_export1 = create(:bulk_export, :finished,
                          user: user,
                          collection: collection,
                          created_at: 40.days.ago)
      old_export2 = create(:bulk_export, :finished,
                          user: user,
                          collection: collection,
                          created_at: 35.days.ago)
      
      # Create files for both
      FileUtils.touch(old_export1.zip_file_name)
      FileUtils.touch(old_export1.log_file)
      FileUtils.touch(old_export2.zip_file_name)
      FileUtils.touch(old_export2.log_file)
      
      # Run the rake task
      Rake::Task['fromthepage:clean_bulk_exports'].reenable
      capture_stdout { Rake::Task['fromthepage:clean_bulk_exports'].invoke(30) }
      
      # Verify both records were deleted
      expect(BulkExport.find_by(id: old_export1.id)).to be_nil
      expect(BulkExport.find_by(id: old_export2.id)).to be_nil
      
      # Verify files were deleted
      expect(File.exist?(old_export1.zip_file_name)).to be false
      expect(File.exist?(old_export2.zip_file_name)).to be false
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
