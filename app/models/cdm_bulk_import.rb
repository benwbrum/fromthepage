# == Schema Information
#
# Table name: cdm_bulk_imports
#
#  id               :integer          not null, primary key
#  cdm_urls         :text(65535)
#  collection_param :string(255)      not null
#  ocr_correction   :boolean          default(FALSE)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :integer          not null
#
# Indexes
#
#  index_cdm_bulk_imports_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class CdmBulkImport < ApplicationRecord
  belongs_to :user

  def submit_background_task
    rake_call = "#{RAKE} fromthepage:bulk_import_cdm[#{self.id}]  --trace  2>&1 &"

    # Nice-up the rake call if settings are present
    rake_call = "nice -n #{NICE_RAKE_LEVEL} " << rake_call if NICE_RAKE_ENABLED

    logger.info rake_call
    system(rake_call)

  end

  def collection_or_document_set
    if md=self.collection_param.match(/D(\d+)/)
      DocumentSet.find_by(id: md[1])
    else
      Collection.find_by(id: self.collection_param)
    end
  end


end
