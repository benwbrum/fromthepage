class ContactMailer < ActionMailer::Base
  default from: SENDING_EMAIL_ADDRESS

  def contact(first_name:, last_name:, reason:, email:, more:)
    @first_name = first_name
    @last_name = last_name
    @email = email
    @reason = reason
    @more = more

    mail to:      ADMIN_EMAILS,
         subject: "New contact us form submission from #{email}"
  end
end
