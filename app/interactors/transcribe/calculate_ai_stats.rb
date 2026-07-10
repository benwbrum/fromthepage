class Transcribe::CalculateAiStats < ApplicationInteractor
  def initialize(page:)
    @page = page
    @ai_transcriptions = @page.ai_transcriptions

    super
  end

  def perform
    @ai_transcriptions.find_each do |ai_transcription|
      ai_accuracy_stats = @page.ai_accuracy_statistics(ai_transcription: ai_transcription, extract_raw_values: true)

      ai_transcription.update!(
        verbatim_cer_distance: ai_accuracy_stats&.dig(:verbatim, :cer_distance),
        verbatim_cer_length: ai_accuracy_stats&.dig(:verbatim, :cer_length),
        verbatim_cer: ai_accuracy_stats&.dig(:verbatim, :cer),
        verbatim_wer_distance: ai_accuracy_stats&.dig(:verbatim, :wer_distance),
        verbatim_wer_length: ai_accuracy_stats&.dig(:verbatim, :wer_length),
        verbatim_wer: ai_accuracy_stats&.dig(:verbatim, :wer),
        verbatim_non_stopword_accuracy: ai_accuracy_stats&.dig(:verbatim, :non_stopword_accuracy),
        text_cer_distance: ai_accuracy_stats&.dig(:text_only, :cer_distance),
        text_cer_length: ai_accuracy_stats&.dig(:text_only, :cer_length),
        text_cer: ai_accuracy_stats&.dig(:text_only, :cer),
        text_wer_distance: ai_accuracy_stats&.dig(:text_only, :wer_distance),
        text_wer_length: ai_accuracy_stats&.dig(:text_only, :wer_length),
        text_wer: ai_accuracy_stats&.dig(:text_only, :wer)
      )
    end
  end
end
