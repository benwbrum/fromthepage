# == Schema Information
#
# Table name: suspicious_behaviors
# Database name: primary
#
#  id                  :bigint           not null, primary key
#  behavior_type       :string(255)      not null
#  metadata            :text(4294967295)
#  resolved_at         :datetime
#  status              :string(255)      default("pending"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  collection_id       :integer
#  page_id             :integer
#  resolved_by_user_id :integer
#  user_id             :integer          not null
#
# Indexes
#
#  index_suspicious_behaviors_on_collection_id        (collection_id)
#  index_suspicious_behaviors_on_page_id              (page_id)
#  index_suspicious_behaviors_on_resolved_by_user_id  (resolved_by_user_id)
#  index_suspicious_behaviors_on_user_id              (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (collection_id => collections.id) ON DELETE => nullify
#  fk_rails_...  (page_id => pages.id) ON DELETE => nullify
#  fk_rails_...  (resolved_by_user_id => users.id) ON DELETE => nullify
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#
class SuspiciousBehavior < ApplicationRecord
  belongs_to :user
  belongs_to :page, optional: true
  belongs_to :collection, optional: true
  belongs_to :resolved_by_user, optional: true, class_name: 'User'

  enum :behavior_type, {
    # Implemented
    large_paste: 'large_paste',
    ai_warning_left: 'ai_warning_left',
    minimal_ai_changes: 'minimal_ai_changes',
    # Pending
    high_wpm: 'high_wpm',
    chatgpt_tell: 'chatgpt_tell',
    low_backspace: 'low_backspace',
    no_image_adjustment: 'no_image_adjustment'
  }

  enum :status, {
    pending: 'pending',
    confirmed: 'confirmed',
    dismissed: 'dismissed'
  }, default: :pending

  # TODO: We need to upgrade our DB version to utilize native json column field.
  # Right now we are technically using long-text field and serializing to JSON
  if (col = columns_hash['metadata']) &&
    !col.sql_type_metadata.sql_type.match?(/\bjson\b/i)
    serialize :metadata, coder: JSON
  end

  # TODO: We will add support for other suspicious_behaviors
  BEHAVIOR_TYPE_FILTERS = [
    :all,
    :large_paste,
    :ai_warning_left,
    :minimal_ai_changes
  ].freeze

  STATUS_FILTERS = [:all, :pending, :confirmed, :dismissed].freeze
end
