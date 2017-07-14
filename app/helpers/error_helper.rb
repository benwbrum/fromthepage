module ErrorHelper
  #SMTP_ERRORS = [IOError, Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPUnknownError, TimeoutError, Net::SMTPFatalError, Net::SMTPSyntaxError]

  def log_smtp_error(e, user)
    logger.error("Document upload by #{user.display_name} at #{Time.now}")
    logger.error("SMTP Failed: Exception: #{e.message}")
  end

end