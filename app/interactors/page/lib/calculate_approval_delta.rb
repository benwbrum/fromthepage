class Page::Lib::CalculateApprovalDelta
  def initialize(page:)
    @page = page
  end

  def perform
    if Page::COMPLETED_STATUSES.exclude?(@page.status)
      # zero out deltas if the page is not complete
      @page.update_column(:approval_delta, nil)

      return
    end

    most_recent_not_approver_version = @page.page_versions.where.not(user_id: Current.user.id).first
    old_transcription = most_recent_not_approver_version&.transcription || ''
    new_transcription = @page.source_text

    if new_transcription.blank? && old_transcription.blank?
      @page.update_column(:approval_delta, nil)
    else
      @page.update_column(:approval_delta, Text::Levenshtein.distance(old_transcription, new_transcription).to_f / (old_transcription.size + new_transcription.size).to_f)
    end
  end
end
