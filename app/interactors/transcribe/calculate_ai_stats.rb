class Transcribe::CalculateAiStats < ApplicationInteractor
  DISTANCE_FLAG = 0.05
  CAVEAT_TEXTS = [
    I18n.t('shared.codemirror.ai_plaintext_caveat'),
    I18n.t('shared.codemirror.ai_plaintext_caveat_no_emoji')
  ].freeze

  def initialize(page:)
    @page = page
    @ai_transcriptions = @page.ai_transcriptions

    super
  end

  def perform
    @ai_transcriptions.find_each do |ai_transcription|
      ai_accuracy_stats = @page.ai_accuracy_statistics(ai_transcription: ai_transcription)

      ai_transcription.update!(
        verbatim_cer: ai_accuracy_stats&.dig(:verbatim, :cer),
        verbatim_wer: ai_accuracy_stats&.dig(:verbatim, :wer),
        verbatim_non_stopword_accuracy: ai_accuracy_stats&.dig(:verbatim, :non_stopword_accuracy),
        text_cer: ai_accuracy_stats&.dig(:text_only, :cer),
        text_wer: ai_accuracy_stats&.dig(:text_only, :wer)
      )
    end
  end
end
