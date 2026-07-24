class SystemMailer < ActionMailer::Base
  include ContributorHelper
  FAILURE_LOG_PATTERN = /\b(fail(?:ed|ures?)?|error(?:s)?)\b/i
  CDM_SYNC_EMAIL_LOG_LINE_LIMIT = 200

  default from: 'FromThePage <support@fromthepage.com>'
  layout 'mailer'

  before_action :add_inline_attachments!

  def config_test(target_email)
    mail from: SENDING_EMAIL_ADDRESS, to: target_email, subject: 'Mail config test for FromThePage'
  end


  def email_stats(hours)
    @hours = hours
    @recent_users = User.where('created_at > ?', Time.now - hours.to_i.hours)
    @recent_deeds = Deed.where('created_at > ?', Time.now - hours.to_i.hours)
    mail from: SENDING_EMAIL_ADDRESS, to: ADMIN_EMAILS, subject: "FromThePage had #{@recent_users.count} new users in last #{hours} hours."
  end


  def cdm_sync_finished(collection)
    @collection = collection
    full_log_contents = ContentdmTranslator.log_contents(collection)
    @log_contents = full_log_contents.lines.last(CDM_SYNC_EMAIL_LOG_LINE_LIMIT).join
    recipients = [ADMIN_EMAILS, owner_emails(collection)].reject(&:blank?).join(', ')
    subject = "CONTENTdm Sync Finished for #{collection.title}"
    subject = "CONTENTdm Sync Finished with Failures for #{collection.title}" if full_log_contents.match?(FAILURE_LOG_PATTERN)
    mail from: SENDING_EMAIL_ADDRESS, to: recipients, subject: subject
  end


  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.system_mailer.new_user.subject
  #
  def new_user
    @greeting = 'Hi'
    mail from: SENDING_EMAIL_ADDRESS, to: ADMIN_EMAILS, subject: 'New FromThePage user '
  end

  def page_save_failed(message, ex)
    @message = message
    @ex = ex
    mail from: SENDING_EMAIL_ADDRESS, to: ADMIN_EMAILS, subject: 'Page save failed'
  end

  private
  def admin_emails
    User.where(admin: true).to_a.map { |u| u.email }
  end

  def add_inline_attachments!
    attachments.inline['logo.png'] = File.read("#{Rails.root}/app/assets/images/logo.png")
  end

  def owner_emails(collection)
    emails = collection.owners.map(&:email)
    emails << collection.owner.email if collection.owner
    emails.uniq.join(', ')
  end
end
