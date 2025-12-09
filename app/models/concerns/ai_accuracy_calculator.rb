# frozen_string_literal: true

require 'stopwords'

# Concern for calculating AI transcription accuracy metrics
# Compares AI-generated text against human-verified ground truth
module AiAccuracyCalculator
  extend ActiveSupport::Concern

  # Check if accuracy statistics can be calculated for this page
  def can_calculate_ai_accuracy?
    has_ai_plaintext? && completed_transcription?
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
  def ai_accuracy_statistics
    return nil unless can_calculate_ai_accuracy?

    ground_truth = verbatim_transcription_plaintext
    ai_text = ai_plaintext

    return nil if ground_truth.blank? && ai_text.blank?

    stats = {
      verbatim: calculate_verbatim_statistics(ground_truth, ai_text),
      text_only: calculate_text_only_statistics(ground_truth, ai_text)
    }

    # Add non-stopword accuracy only if language is supported
    if can_calculate_non_stopword_accuracy?
      stats[:verbatim][:non_stopword_accuracy] = non_stopword_accuracy(ground_truth, ai_text)
    end

    stats
  end

  private

  # Check if page has a completed transcription status
  def completed_transcription?
    # Use Page model's COMPLETED_STATUSES but exclude translation status
    # since transcription happens before translation
    transcription_completed_statuses = [
      Page.statuses[:blank],
      Page.statuses[:indexed],
      Page.statuses[:transcribed]
    ]
    transcription_completed_statuses.include?(status)
  end

  # Calculate statistics for verbatim text (with punctuation and formatting)
  def calculate_verbatim_statistics(ground_truth, ai_text)
    {
      cer: character_error_rate(ground_truth, ai_text),
      wer: word_error_rate(ground_truth, ai_text)
    }
  end

  # Calculate statistics for text-only versions (normalized text)
  def calculate_text_only_statistics(ground_truth, ai_text)
    normalized_truth = normalize_text(ground_truth)
    normalized_ai = normalize_text(ai_text)

    {
      cer: character_error_rate(normalized_truth, normalized_ai),
      wer: word_error_rate(normalized_truth, normalized_ai)
    }
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
  # CER = Levenshtein distance / length of ground truth
  def character_error_rate(ground_truth, predicted)
    return 0.0 if ground_truth == predicted
    return 100.0 if ground_truth.blank? || predicted.blank?

    distance = Text::Levenshtein.distance(ground_truth, predicted).to_f
    max_length = ground_truth.length
    return 0.0 if max_length.zero?

    (distance / max_length * 100.0).round(2)
  end

  # Calculate Word Error Rate (WER)
  # WER = Levenshtein distance on words / number of words in ground truth
  def word_error_rate(ground_truth, predicted)
    ground_truth_words = ground_truth.split(/\s+/).reject(&:blank?)
    predicted_words = predicted.split(/\s+/).reject(&:blank?)

    return 0.0 if ground_truth_words == predicted_words
    return 100.0 if ground_truth_words.empty? || predicted_words.empty?

    # Calculate Levenshtein distance at word level
    distance = word_levenshtein_distance(ground_truth_words, predicted_words).to_f
    max_length = [ground_truth_words.length, predicted_words.length].max
    return 0.0 if max_length.zero?

    (distance / max_length * 100.0).round(2)
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
