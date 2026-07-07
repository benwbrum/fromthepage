class Transcribe::FlagHighWpm < ApplicationInteractor
  HIGH_WPM_THRESHOLD = 300

  def initialize(page:, user:)
    @page = page
    @user = user
    @collection = page.collection

    super
  end

  def perform
    return unless new_transcription_created?

    words = word_count
    return if words.zero?

    duration_seconds = transcription_duration_seconds
    return unless duration_seconds&.positive?

    wpm = (words * 60.0) / duration_seconds
    return unless wpm > HIGH_WPM_THRESHOLD

    SuspiciousBehaviors::Create.new(
      collection: @collection,
      page: @page,
      user: @user,
      suspicious_behavior_params: {
        behavior_type: :high_wpm,
        metadata: {
          wpm: wpm.round(2),
          duration_seconds: duration_seconds,
          words: words
        }
      }
    ).call
  end

  private

  def new_transcription_created?
    @page.saved_change_to_source_text? &&
      @page.source_text_before_last_save.to_s.blank? &&
      @page.source_text.present?
  end

  def word_count
    @page.source_text.scan(/\b[[:alnum:]']+\b/).size
  end

  def transcription_duration_seconds
    events_scope = Ahoy::Event
                   .where(user_id: @user.id, name: 'transcribe#display_page')
                   .where('time > ?', 1.day.ago)
                   .order(time: :desc)

    display_event = if mysql_adapter?
                      events_scope.where("JSON_EXTRACT(properties, '$.page_id') = ?", @page.id).first
    else
                      events_scope.limit(25).detect { |event| event.properties['page_id'] == @page.id }
    end

    return if display_event.nil?

    (Time.current - display_event.time).to_i
  end

  def mysql_adapter?
    ActiveRecord::Base.connection.adapter_name.downcase.include?('mysql')
  end
end
