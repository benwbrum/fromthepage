module DeviseHelper

  def devise_error_messages!
    flash_alerts = []
    error_key = 'errors.messages.not_saved'

    unless flash.empty?
      error_key = 'errors.messages.not_signed'

      if flash[:error]
        flash_alerts.push(flash[:error])
      elsif flash[:alert]
        flash_alerts.push(flash[:alert])
      elsif flash[:info]
        flash_alerts.push(flash[:info])
      elsif flash[:notice]
        flash_alerts.push(flash[:notice])
        error_key = nil
      end

      flash.clear
    end

    return '' if resource.errors.empty? && flash_alerts.empty?

    if resource.errors.empty?
      errors = flash_alerts
    else
      errors = resource.errors.messages.map do |key, msg|
        if key == :reset_password_token
          I18n.t('devise.errors.messages.reset_password.invalid_token')
        else
          "#{I18n.t("devise.errors.keys.#{key}")} #{msg.first}"
        end
      end
    end

    messages = errors.map { |msg| content_tag(:li, msg) }.join

    if error_key
      sentence = I18n.t(error_key, count: errors.count, resource: resource.class.model_name.human.downcase)
      html = <<-HTML
      <div class="validation">
        <h5 class="validation_title">#{sentence}</h5>
        <ul class="validation_summary">#{messages}</ul>
      </div>
      HTML
    else
      html = <<-HTML
      <div class="validation success">
        <ul class="validation_summary">#{messages}</ul>
      </div>
      HTML
    end

    html.html_safe
  end

end
