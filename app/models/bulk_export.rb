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
    self.status = Status::PROCESSING
    self.save
    # TODO read config options
    works = Work.includes(pages: [:notes, {page_versions: :user}]).where(collection_id: self.collection.id)

    buffer = Zip::OutputStream.open(zip_file_name) do |out|
      write_work_exports(works, out, self.user, self)
      out.close
    end

    self.status = Status::FINISHED
    self.save
  end

  def clean_zip_file
    File.unlink(zip_file_name) if File.exist?(zip_file_name)
    File.unlink(log_file) if File.exist?(log_file)
    self.status = Status::CLEANED
    self.save
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
    File.join(zip_file_path, "rake_bulk_export_#{self.id}.log")
  end

  def log_contents
    if File.exist?(log_file)
      File.read(log_file)
    else
      "Log file has been cleaned"
    end
  end

  def zip_file_path
    path = "/tmp/fromthepage_exports"
    FileUtils.mkdir_p(path)

    path
  end

  def zip_file_name
    File.join(zip_file_path, "export_#{self.id}.zip")
  end


end
