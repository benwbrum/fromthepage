# frozen_string_literal: true

require 'stopwords'

# Concern for calculating AI transcription accuracy metrics
# Compares AI-generated text against human transcription
module AiAccuracyCalculator
  extend ActiveSupport::Concern

  # Check if accuracy statistics can be calculated for this page
  def can_calculate_ai_accuracy?(ai_transcription: nil)
    has_ai_plaintext?(ai_transcription_to_use: ai_transcription) && has_human_transcription?
  end

  # Check if non-stopword accuracy can be calculated for this collection's language
  def can_calculate_non_stopword_accuracy?
    return false unless collection&.text_language.present?
    lang_code = ISO_639.find(collection.text_language).alpha2
    # Snowball::Filter will thrown an exception if initialized on a language it doesn't support
    if lang_code
      begin
        Stopwords::Snowball::Filter.new(lang_code)
        true
      rescue ArgumentError
        false
      end
    end
  end

  # Calculate all accuracy statistics
  # Returns a hash with various accuracy metrics or nil if cannot calculate
  def ai_accuracy_statistics(ai_transcription: self.ai_transcription, extract_raw_values: false)
    return nil unless can_calculate_ai_accuracy?(ai_transcription: ai_transcription)

    ground_truth = ground_truth_for_comparison
    ai_text = ai_transcription&.text_for_comparison

    return nil if ground_truth.blank? && ai_text.blank?

    stats = {
      verbatim: calculate_verbatim_statistics(ground_truth, ai_text, extract_raw_values),
      text_only: calculate_text_only_statistics(ground_truth, ai_text, extract_raw_values)
    }

    # Add non-stopword accuracy only if language is supported
    if can_calculate_non_stopword_accuracy?
      stats[:verbatim][:non_stopword_accuracy] = non_stopword_accuracy(ground_truth, ai_text)
    end

    stats
  end

  private

  # Check if page has human transcription content
  def has_human_transcription?
    xml_text.present?
  end

  # Calculate statistics for verbatim text (with punctuation and formatting)
  def calculate_verbatim_statistics(ground_truth, ai_text, extract_raw_values = false)
    if extract_raw_values
      cer_distance, cer_length, cer = character_error_rate(ground_truth, ai_text, extract_raw_values)
      wer_distance, wer_length, wer = word_error_rate(ground_truth, ai_text, extract_raw_values)
      {
        cer_distance: cer_distance,
        cer_length: cer_length,
        cer: cer,
        wer_distance: wer_distance,
        wer_length: wer_length,
        wer: wer
      }
    else
      {
        cer: character_error_rate(ground_truth, ai_text),
        wer: word_error_rate(ground_truth, ai_text)
      }
    end
  end

  # Calculate statistics for text-only versions (normalized text)
  def calculate_text_only_statistics(ground_truth, ai_text, extract_raw_values = false)
    normalized_truth = normalize_text(ground_truth)
    normalized_ai = normalize_text(ai_text)

    if extract_raw_values
      cer_distance, cer_length, cer = character_error_rate(normalized_truth, normalized_ai, extract_raw_values)
      wer_distance, wer_length, wer = word_error_rate(normalized_truth, normalized_ai, extract_raw_values)
      {
        cer_distance: cer_distance,
        cer_length: cer_length,
        cer: cer,
        wer_distance: wer_distance,
        wer_length: wer_length,
        wer: wer
      }
    else
      {
        cer: character_error_rate(normalized_truth, normalized_ai),
        wer: word_error_rate(normalized_truth, normalized_ai)
      }
    end
  end

  # Normalize text by removing punctuation, extra whitespace, and converting to lowercase
  def normalize_text(text)
    return '' if text.blank?

    # Remove punctuation
    normalized = text.gsub(/[[:punct:]]/, ' ')
    # Convert to lowercase
    normalized = normalized.downcase
    # Collapse multiple spaces into one
    normalized = normalized.gsub(/\s+/, ' ')
    # Trim leading/trailing whitespace
    normalized.strip
  end

  # Calculate Character Error Rate (CER)
  # CER = Levenshtein distance / length of human transcription
  # extract_raw_values will return [distance, length, cer]
  def character_error_rate(ground_truth, predicted, extract_raw_values = false)
    max_length = ground_truth.length

    if ground_truth == predicted
      return extract_raw_values ? [0.0, max_length, 0.0] : 0.0
    end

    if ground_truth.blank? || predicted.blank?
      return extract_raw_values ? [max_length, max_length, 100.0] : 100.0
    end

    distance = Text::Levenshtein.distance(ground_truth, predicted).to_f
    if max_length.zero?
      return extract_raw_values ? [distance, max_length, 0.0] : 0.0
    end

    cer = (distance / max_length * 100.0).round(2)

    extract_raw_values ? [distance, max_length, cer] : cer
  end

  # Calculate Word Error Rate (WER)
  # WER = Levenshtein distance on words / number of words in human transcription
  # extract_raw_values will return [distance, length, wer]
  def word_error_rate(ground_truth, predicted, extract_raw_values = false)
    ground_truth_words = ground_truth.split(/\s+/).reject(&:blank?)
    predicted_words = predicted.split(/\s+/).reject(&:blank?)

    ground_truth_length = ground_truth_words.length

    if ground_truth_words == predicted_words
      return extract_raw_values ? [0.0, ground_truth_length, 0.0] : 0.0
    end

    if ground_truth_words.empty? || predicted_words.empty?
      return extract_raw_values ? [ground_truth_length, ground_truth_length, 100.0] : 100.0
    end

    # Calculate Levenshtein distance at word level
    distance = word_levenshtein_distance(ground_truth_words, predicted_words).to_f
    if ground_truth_length.zero?
      return extract_raw_values ? [distance, ground_truth_length, 0.0] : 0.0
    end

    wer = (distance / ground_truth_length * 100.0).round(2)
    extract_raw_values ? [distance, ground_truth_length, wer] : wer
  end

  # Calculate Levenshtein distance for arrays of words
  def word_levenshtein_distance(words1, words2)
    m = words1.length
    n = words2.length
    return n if m.zero?
    return m if n.zero?

    # Create distance matrix
    d = Array.new(m + 1) { Array.new(n + 1, 0) }

    (0..m).each { |i| d[i][0] = i }
    (0..n).each { |j| d[0][j] = j }

    (1..m).each do |i|
      (1..n).each do |j|
        cost = words1[i - 1] == words2[j - 1] ? 0 : 1
        d[i][j] = [
          d[i - 1][j] + 1,      # deletion
          d[i][j - 1] + 1,      # insertion
          d[i - 1][j - 1] + cost # substitution
        ].min
      end
    end

    d[m][n]
  end

  # Calculate accuracy based on non-stopword matches
  # This focuses on content words rather than common function words
  def non_stopword_accuracy(ground_truth, predicted)
    ground_truth_words = extract_non_stopwords(ground_truth)
    predicted_words = extract_non_stopwords(predicted)

    return 100.0 if ground_truth_words.empty? && predicted_words.empty?
    return 0.0 if ground_truth_words.empty? || predicted_words.empty?
    non_stopword_wer= word_error_rate(ground_truth_words.join(' '), predicted_words.join(' '))
    (100.0 - non_stopword_wer).round(2)
  end

  # Extract non-stopwords from text using stopwords-filter gem
  def extract_non_stopwords(text)
    return [] if text.blank?
    return [] unless collection&.text_language.present?

    lang_code = ISO_639.find(collection.text_language).alpha2

    # Split into words, remove punctuation, convert to lowercase
    words = text.downcase.scan(/\b[\w]+\b/)

    # Use stopwords-filter to remove stopwords
    filter = Stopwords::Snowball::Filter.new(lang_code)
    filter.filter(words)
  end
end
