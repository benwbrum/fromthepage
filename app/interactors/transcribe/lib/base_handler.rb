class Transcribe::Lib::BaseHandler
  private

  def record_deed(deed_params)
    Deed.create!(deed_params)

    update_search_attempt_contributions
  end

  def update_search_attempt_contributions
    search_attempt_id = Current.session&.dig(:search_attempt_id)
    return unless search_attempt_id.present?

    search_attempt = SearchAttempt.find(search_attempt_id)
    search_attempt.increment!(:contributions)
  end
end
