class HtmlValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    return unless value&.match?(/<[^>]+>/) # Regex to check if it follows html syntax

    begin
      REXML::Document.new("<html>#{value}</html>")
    rescue REXML::ParseException
      message = options[:message] || :html_syntax_error
      record.errors.add(attribute, message)
    end
  end

end
