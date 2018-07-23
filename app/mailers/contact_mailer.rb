class ContactMailer < ActionMailer::Base
  def contact(first_name:, last_name:, reason:, email:, more:)
    @first_name = first_name
    @last_name = last_name
    @email = email
    @reason = reason
    @more = more

    mail from:    email,
         to:      ENV['CONTACT_EMAIL_RECIPIENT'],
         subject: 'New contact us form submission'
  end
end
