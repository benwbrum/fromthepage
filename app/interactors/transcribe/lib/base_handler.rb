class Transcribe::Lib::BaseHandler
  private

  def transcript_date
    @transcript_date ||= Time.now
  end

  def logger
    Rails.logger
  end

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

  def log_attempt(attempt_type, source_text)
    lines = [
      "#{attempt_type}\t#{transcript_date}",
      "#{attempt_type}\tUser\tID: #{@user.id}\tEmail: #{@user.email}\tDisplay Name: #{@user.display_name}",
      "#{attempt_type}\tCollection\tID: #{@page.collection.id}\tTitle: #{@page.collection.title}\tOwner Email: #{@page.collection.owner.email}",
      "#{attempt_type}\tWork\tID: #{@page.work.id}\tTitle: #{@page.work.title}",
      "#{attempt_type}\tPage\tID: #{@page.id}\tPosition: #{@page.position}\tTitle: #{@page.title}",
      "#{attempt_type}\tSource Text:",
      'BEGIN_SOURCE_TEXT',
      source_text,
      'END_SOURCE_TEXT',
      ''
    ]

    message = lines.join("\n")
    logger.info(message)

    message
  end

  def log_success(attempt_type)
    message = "#{attempt_type}\t#{transcript_date}\tSUCCESS\t"
    logger.info(message)
  end

  def log_error(attempt_type, message)
    log_message = "#{attempt_type}\t#{transcript_date}\tERROR\t"
    logger.info(@page.errors[:base].join("\t#{log_message}"))
    log_email_error(message, @page.errors[:base])
  end

  def log_email_error(message, ex)
    if SMTP_ENABLED
      begin
        SystemMailer.page_save_failed(message, ex).deliver!
      rescue StandardError => e
        logger.info("SMTP Failed: Exception: #{e.message}")
      end
    end
  end
end
