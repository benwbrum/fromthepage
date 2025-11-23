# == Schema Information
#
# Table name: suspicious_behaviors
#
#  id                  :integer          not null, primary key
#  behavior_type       :string(255)      not null
#  flagged_at          :datetime         not null
#  metadata            :json
#  resolved_at         :datetime
#  status              :string(255)      default("pending"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  collection_id       :integer          not null
#  deed_id             :integer
#  page_id             :integer
#  resolved_by_user_id :integer
#  user_id             :integer          not null
#
# Indexes
#
#  index_suspicious_behaviors_on_collection_id               (collection_id)
#  index_suspicious_behaviors_on_collection_id_and_status    (collection_id,status)
#  index_suspicious_behaviors_on_deed_id                     (deed_id)
#  index_suspicious_behaviors_on_page_id                     (page_id)
#  index_suspicious_behaviors_on_resolved_by_user_id         (resolved_by_user_id)
#  index_suspicious_behaviors_on_status                      (status)
#  index_suspicious_behaviors_on_user_id                     (user_id)
#  index_suspicious_behaviors_on_user_id_and_behavior_type   (user_id,behavior_type,flagged_at)
#
# Foreign Keys
#
#  fk_rails_...  (collection_id => collections.id)
#  fk_rails_...  (deed_id => deeds.id)
#  fk_rails_...  (page_id => pages.id)
#  fk_rails_...  (resolved_by_user_id => users.id)
#  fk_rails_...  (user_id => users.id)
#
class SuspiciousBehavior < ApplicationRecord
  # Behavior types
  BEHAVIOR_TYPES = %w[
    paste_detected
    high_wpm
    chatgpt_tell
    low_backspace
    no_image_adjustment
  ].freeze

  # Status values
  STATUSES = %w[pending approved dismissed].freeze

  belongs_to :user
  belongs_to :page, optional: true
  belongs_to :collection
  belongs_to :deed, optional: true
  belongs_to :resolved_by_user, class_name: 'User', optional: true

  validates :behavior_type, inclusion: { in: BEHAVIOR_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :flagged_at, presence: true

  scope :pending, -> { where(status: 'pending') }
  scope :resolved, -> { where.not(resolved_at: nil) }
  scope :for_collection, ->(collection) { where(collection: collection) }
  scope :for_user, ->(user) { where(user: user) }
  scope :recent, -> { order(flagged_at: :desc) }
  scope :paste_events, -> { where(behavior_type: 'paste_detected') }

  # Check if this is the first suspicious behavior of this type for a user
  def first_offense?
    SuspiciousBehavior.where(
      user: user,
      behavior_type: behavior_type
    ).where('flagged_at < ?', flagged_at).none?
  end

  # Resolve the behavior
  def resolve!(resolved_by:, new_status:)
    update!(
      status: new_status,
      resolved_at: Time.current,
      resolved_by_user: resolved_by
    )
  end

  # Get human-readable behavior type name
  def behavior_type_name
    behavior_type.humanize
  end
end
