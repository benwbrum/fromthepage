# == Schema Information
#
# Table name: bulk_exports
#
#  id                                 :integer          not null, primary key
#  admin_searches                     :boolean
#  collection_activity                :boolean
#  collection_contributors            :boolean
#  facing_edition_work                :boolean
#  html_page                          :boolean
#  html_work                          :boolean
#  notes_csv                          :boolean
#  organization                       :string(255)      default("by_work")
#  owner_detailed_activity            :boolean
#  owner_mailing_list                 :boolean
#  plaintext_emended_page             :boolean
#  plaintext_emended_work             :boolean
#  plaintext_searchable_page          :boolean
#  plaintext_searchable_work          :boolean
#  plaintext_verbatim_page            :boolean
#  plaintext_verbatim_work            :boolean
#  plaintext_verbatim_zero_index_page :boolean          default(FALSE)
#  report_arguments                   :string(255)
#  static                             :boolean
#  status                             :string(255)      default("new")
#  subject_csv_collection             :boolean
#  subject_details_csv_collection     :boolean
#  table_csv_collection               :boolean
#  table_csv_work                     :boolean
#  tei_work                           :boolean
#  text_docx_work                     :boolean
#  text_only_pdf_work                 :boolean
#  text_pdf_work                      :boolean
#  use_uploaded_filename              :boolean          default(TRUE)
#  work_metadata_csv                  :boolean          default(FALSE)
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  collection_id                      :integer
#  document_set_id                    :integer
#  user_id                            :integer          not null
#  work_id                            :integer
#
# Indexes
#
#  index_bulk_exports_on_collection_id    (collection_id)
#  index_bulk_exports_on_document_set_id  (document_set_id)
#  index_bulk_exports_on_user_id          (user_id)
#  index_bulk_exports_on_work_id          (work_id)
#
# Foreign Keys
#
#  fk_rails_...  (collection_id => collections.id)
#  fk_rails_...  (document_set_id => document_sets.id)
#  fk_rails_...  (user_id => users.id)
#  fk_rails_...  (work_id => works.id)
#
class BulkExport < ApplicationRecord
  require 'zip'
  include ExportHelper, ExportService
  store :report_arguments, accessors: [:preserve_linebreaks, :include_metadata, :include_contributors, :start_date, :end_date], coder: JSON

  belongs_to :user
  belongs_to :collection, optional: true
  belongs_to :document_set, optional: true
  belongs_to :work, optional: true

  # enum status: {
  #   new: 'new',
  #   queued: 'queued',
  #   processing: 'processing',
  #   finished: 'finished',
  #   cleaned: 'cleaned',
  #   error: 'error'
  # }, _prefix: :status

  # enum organization: {
  #   by_format: 'by_format',
  #   by_work: 'by_work'
  # }, _prefix: :organization

  module Status
    NEW = 'new'
    QUEUED = 'queued'
    PROCESSING = 'processing'
    FINISHED = 'finished'
    CLEANED = 'cleaned'
    ERROR = 'error'
  end

  module Organization
    FORMAT_THEN_WORK = 'by_format'
    WORK_THEN_FORMAT = 'by_work'
  end

  def work_level?
    self.attributes.detect{|k,v| k.match(/_work/) && v==true }
  end

  def page_level?
    self.attributes.detect{|k,v| k.match(/_page/) && v==true }
  end

  def export_to_zip
    self.status = Status::PROCESSING
    self.save

    begin
      if self.work
        works=[self.work]
      elsif self.document_set
        works = self.document_set.works.includes(pages: [:notes, {page_versions: :user}])
      elsif self.collection
        works = Work.includes(pages: [:notes, {page_versions: :user}]).where(collection_id: self.collection.id)
      else
        works = []
      end

      buffer = Zip::OutputStream.open(zip_file_name) do |out|
        write_work_exports(works, out, self.user, self)
        out.close
      end

      self.status = Status::FINISHED
      self.save

    rescue => ex
      self.status = Status::ERROR
      self.save

      raise
    end
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
    rake_call = "nice -n #{NICE_RAKE_LEVEL} stdbuf -oL " << rake_call if NICE_RAKE_ENABLED

    logger.info rake_call
    system('env > /home/fromthepage/environment_logging/env_from_application.log')
    Rails.logger.info("whoami is \n" + `whoami`)
    Rails.logger.info("pwd is \n" + `pwd`)
    Rails.logger.info("ulimit -a is \n" + `/bin/bash -c "ulimit -a"`)
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
