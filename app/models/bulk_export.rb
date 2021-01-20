class BulkExport < ApplicationRecord
  require 'zip'
  include ExportHelper, ExportService

  belongs_to :user
  belongs_to :collection


  module Status
    NEW = 'new'
    QUEUED = 'queued'
    PROCESSING = 'processing'
    FINISHED = 'finished'
    CLEANED = 'cleaned'
  end


  def export_to_zip
    # TODO read config options
    works = Work.includes(pages: [:notes, {page_versions: :user}]).where(collection_id: self.collection.id)
    zipfile_name = "/tmp/wingingit.zip"

    buffer = Zip::OutputStream.open(zipfile_name) do |out|
      write_work_exports(works, out, self.user)
      out.close
    end

  end


  def submit_export_process
    self.status = Status::QUEUED
    self.save
    rake_call = "#{RAKE} fromthepage:process_bulk_export[#{self.id}]  --trace >> #{log_file} 2>&1 &"

    # Nice-up the rake call if settings are present
    rake_call = "nice -n #{NICE_RAKE_LEVEL} " << rake_call if NICE_RAKE_ENABLED

    logger.info rake_call
    system(rake_call)
  end

  def log_file
    "/tmp/fromthepage_rake_bulk_export_#{self.id}.log"
  end

  def log_contents
    File.read(log_file)
  end

end
