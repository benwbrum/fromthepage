# == Schema Information
#
# Table name: segmentation_logs
#
#  id                      :bigint           not null, primary key
#  error_message           :text(65535)
#  is_first_page_candidate :boolean
#  metadata                :text(4294967295)
#  model                   :string(255)      not null
#  status                  :string(255)      default("finished"), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  page_id                 :integer          not null
#  work_id                 :integer          not null
#
# Indexes
#
#  index_segmentation_logs_on_page_id  (page_id)
#  index_segmentation_logs_on_work_id  (work_id)
#
# Foreign Keys
#
#  fk_rails_...  (page_id => pages.id) ON DELETE => cascade
#
class SegmentationLog < ApplicationRecord
  belongs_to :page
  belongs_to :work

  # TODO: We need to upgrade our DB version to utilize native json column field.
  # Right now we are technically using long-text field and serializing to JSON
  if (col = columns_hash['metadata']) &&
    !col.sql_type_metadata.sql_type.match?(/\bjson\b/i)
    serialize :metadata, coder: JSON
  end

  validates :model, presence: true

  enum :status, {
    finished: 'finished',
    error: 'error'
  }, default: :finished

  def total_token_count
    return 0 unless metadata.is_a?(Hash)

    %w[prompt_token_count candidates_token_count thoughts_token_count].sum { |key| metadata[key].to_i }
  end
end
