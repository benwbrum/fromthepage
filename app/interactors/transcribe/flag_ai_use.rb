class Transcribe::FlagAiUse < ApplicationInteractor
  DISTANCE_FLAG = 0.05
  CAVEAT_TEXTS = [
    I18n.t('shared.codemirror.ai_plaintext_caveat'),
    I18n.t('shared.codemirror.ai_plaintext_caveat_no_emoji')
  ].freeze

  def initialize(page:, user:)
    @page = page
    @user = user
    @collection = page.collection

    super
  end

  def perform
    handle_ai_warning_left
    handle_minimal_ai_changes
  end

  private

  def handle_ai_warning_left
    return unless CAVEAT_TEXTS.any? { |text| @page.source_text.include?(text) }

    create_suspicious_behavior(
      behavior_type: :ai_warning_left,
      metadata: {
        content: @page.source_text
      }
    )
  end

  def handle_minimal_ai_changes
    ai_text = strip_ai_caveats(@page.ai_transcription.source_text)
    source_text = strip_ai_caveats(@page.source_text)

    distance = Text::Levenshtein.distance(ai_text, source_text).to_f / (ai_text.size + source_text.size).to_f

    return unless distance.abs < DISTANCE_FLAG

    create_suspicious_behavior(
      behavior_type: :minimal_ai_changes,
      metadata: {
        content: source_text
      }
    )
  end

  def create_suspicious_behavior(behavior_type:, metadata:)
    SuspiciousBehavior.create!(
      user_id: @user.id,
      collection_id: @collection.id,
      page_id: @page.id,
      behavior_type: behavior_type,
      metadata: metadata
    )
  end

  def strip_ai_caveats(text)
    return text unless text.present?

    CAVEAT_TEXTS.reduce(text) do |result, caveat|
      result.gsub(caveat, '')
    end
  end
end
