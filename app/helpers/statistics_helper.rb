module StatisticsHelper
  def fe_counter(count:, text:)
    content_tag(:div, class: 'counter', data: { prefix: "#{number_with_delimiter count}" }) do
      text
    end
  end
end
