class HtmlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    preprocessed = value.dup || ''
    preprocessed.gsub!('&', '&amp;')
    preprocessed.gsub!(/&(amp;)+/, '&amp;')

    validation = Nokogiri::XML("<html>#{preprocessed}</html>")

    return if validation.errors.blank?

    record.errors.add(attribute, I18n.t('errors.html_syntax_error'))
    validation.errors.each do |error|
      record.errors.add(attribute, error.message)
    end
  end
end
