# == Schema Information
#
# Table name: work_statistics
#
#  id                      :integer          not null, primary key
#  annotated_pages         :integer
#  blank_pages             :integer          default(0)
#  complete                :integer
#  corrected_pages         :integer
#  incomplete_pages        :integer          default(0)
#  last_edit_at            :datetime
#  line_count              :integer
#  needs_review            :integer
#  needs_review_percentage :integer
#  total_pages             :integer
#  transcribed_pages       :integer
#  transcribed_percentage  :integer
#  translated_annotated    :integer
#  translated_blank        :integer
#  translated_pages        :integer
#  translated_review       :integer
#  translation_complete    :integer
#  created_at              :datetime
#  updated_at              :datetime
#  work_id                 :integer
#
# Indexes
#
#  index_work_statistics_on_work_id_and_line_count  (work_id,line_count)
#
class WorkStatistic < ApplicationRecord
  belongs_to :work, optional: true

  def pct_transcribed
    raw = self[:transcribed_pages].to_f / self[:total_pages] * 100
    raw = 0.0 if raw.nan?
    [[0, raw].max, 100].min.round(2)
  end

  def pct_semi_transcribed
    raw = (self[:transcribed_pages].to_f + self[:needs_review].to_f) / self[:total_pages] * 100
    raw = 0.0 if raw.nan?
    [[0, raw].max, 100].min.round(2)
  end

  def pct_corrected
    raw = self[:corrected_pages].to_f / self[:total_pages] * 100
    raw = 0.0 if raw.nan?
    [[0, raw].max, 100].min.round(2)
  end

  def pct_translated
    raw = self[:translated_pages].to_f / self[:total_pages] * 100
    raw = 0.0 if raw.nan?
    [[0, raw].max, 100].min.round(2)
  end

  def pct_annotated
    raw = (self[:annotated_pages].to_f + self[:blank_pages].to_f) / self[:total_pages] * 100
    raw = 0.0 if raw.nan?
    [[0, raw].max, 100].min.round(2)
  end

  def pct_translation_annotated
    raw = (self[:translated_annotated].to_f + self[:translated_blank].to_f) / self[:total_pages] * 100
    raw = 0.0 if raw.nan?
    [[0, raw].max, 100].min.round(2)
  end

  def pct_needs_review
    raw = self[:needs_review].to_f / self[:total_pages] * 100
    raw = 0.0 if raw.nan?
    [[0, raw].max, 100].min.round(2)
  end

  def pct_translation_needs_review
    raw = self[:translated_review].to_f / self[:total_pages] * 100
    raw = 0.0 if raw.nan?
    [[0, raw].max, 100].min.round(2)
  end

  def pct_blank
    raw = self[:blank_pages].to_f / self[:total_pages] * 100
    raw = 0.0 if raw.nan?
    [[0, raw].max, 100].min.round(2)
  end

  def pct_translation_blank
    raw = self[:translated_blank].to_f / self[:total_pages] * 100
    raw = 0.0 if raw.nan?
    [[0, raw].max, 100].min.round(2)
  end

  def pct_transcribed_or_blank
    (pct_blank + pct_transcribed).round(2)
  end

  def pct_translated_or_blank
    (pct_translation_blank + pct_translated).round(2)
  end

  def pct_completed
    if work.ocr_correction
      (pct_corrected + pct_annotated).round(2)
    else
      (pct_transcribed + pct_annotated).round(2)
    end
  end

  def pct_translation_completed
    (pct_translated + pct_translation_annotated).round(2)
  end

  def update_last_edit_date
    self.update(last_edit_at: Time.now)
  end

  def recalculate(_options = {})
    recalculate_from_hash
    recalculate_parent_statistics
  end

  def recalculate_from_hash(stats = nil)
    stats = get_stats_hash if stats.nil?

    self[:total_pages] = stats[:total]

    self[:transcribed_pages]  = stats[:transcription][Page.statuses[:transcribed]] || 0
    self[:corrected_pages]    = stats[:transcription][Page.statuses[:transcribed]] || 0
    self[:blank_pages]        = stats[:transcription][Page.statuses[:blank]] || 0
    self[:annotated_pages]    = stats[:transcription][Page.statuses[:indexed]] || 0
    self[:needs_review]       = stats[:transcription][Page.statuses[:needs_review]] || 0

    self[:translated_pages]     = stats[:translation][Page.translation_statuses[:translated]] || 0
    self[:translated_blank]     = stats[:translation][Page.translation_statuses[:blank]] || 0
    self[:translated_annotated] = stats[:translation][Page.translation_statuses[:indexed]] || 0
    self[:translated_review]    = stats[:translation][Page.translation_statuses[:needs_review]] || 0

    self[:complete]                = pct_completed
    self[:transcribed_percentage]  = pct_semi_transcribed.round
    self[:needs_review_percentage] = pct_needs_review.round
    self[:translation_complete]    = pct_translation_completed
    self[:line_count]              = stats[:line_count]

    save!
  end

  def get_stats_hash
    status_counts = work.pages.group(:status).count
    status_counts_with_values = status_counts.transform_keys { |key| Page.statuses.stringify_keys[key] }

    translation_status_counts = work.pages.group(:translation_status).count
    translation_status_counts_with_values =
      translation_status_counts.transform_keys { |key| Page.translation_statuses.stringify_keys[key] }

    {
      transcription: status_counts_with_values,
      translation: translation_status_counts_with_values,
      total: work.pages.count,
      line_count: work.pages.sum(:line_count)
    }
  end

  private

  # current logic to recalculate statistics for parent document set and parent collection
  def recalculate_parent_statistics
    # save completed information for collections/document sets
    work.collection&.calculate_complete
    unless work.document_sets.empty?
      work.document_sets.each(&:calculate_complete)
    end
  end
end
