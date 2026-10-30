class SubjectHeadingInventory < ApplicationRecord
  belongs_to :transcription_field
  has_many :subject_headings, dependent: :delete_all
  serialize :source_rows, coder: JSON

  STATUSES = %w[not_requested queued running completed failed].freeze
  validates :validation_status, inclusion: { in: STATUSES }

  def queue_validation!(user: Current.user || transcription_field.collection.owner)
    with_lock do
      update!(validation_status: 'queued', validation_token: SecureRandom.uuid,
              report_csv: nil, validation_error: nil, completed_at: nil, notified_at: nil)
    end
    job = SubjectHeadings::ValidateJob.perform_later(user_id: user.id, inventory_id: id, token: validation_token)
    raise ActiveJob::EnqueueError, 'Validation enqueue failed' unless job
  rescue ActiveJob::EnqueueError
    update!(validation_status: 'failed', validation_error: 'The authority check could not be queued. Uploaded headings remain available. Please retry.')
  end
end
