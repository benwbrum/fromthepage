class Work::ImportAnnotationTextJob < ApplicationJob
  queue_as :default

  def perform(user_id:, work_id:)
    work = Work.find_by(id: work_id)
    user = User.find_by(id: user_id)
    return if work.nil? || work.sc_manifest.nil?

    result = Work::ImportAnnotationText.new(work: work, user: user).call

    # a retry skips the pages that already received text
    raise result.full_errors unless result.success?
  end
end
