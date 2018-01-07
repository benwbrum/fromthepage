module I18nHelper
  
  def set_locale
    if params[:locale]
      I18n.locale = params[:locale]
    else
      logger.debug "* Accept-Language: #{request.env['HTTP_ACCEPT_LANGUAGE']}"
      I18n.locale = extract_locale_from_accept_language_header || I18n.default_locale
      logger.debug "* Locale set to '#{I18n.locale}'"
    end
  end
   
  private
    def extract_locale_from_accept_language_header
      request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
    end

end
