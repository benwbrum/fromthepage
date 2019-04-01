class SystemMailerPreview < ActionMailer::Preview
  def page_save_failed
    SystemMailer.page_save_failed("failure message", "exception message")
  end

end