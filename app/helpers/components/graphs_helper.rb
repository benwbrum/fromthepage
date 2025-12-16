module Components::GraphsHelper
  SUPPORTED_CHART_TYPES = {
    stacked_bar: 'StackedBar'
  }

  def fe_stacked_bar(title:, labels: [], values: [], colors: [], options: {})
    data_payload = {
      data: {
        labels: [title],
        datasets: values.map.with_index do |value, i|
          is_first = i == 0 || values[0...i].all?(&:zero?)
          is_last = values[i+1..-1].all?(&:zero?)

          border_radius =
            if is_first && is_last
              {
                'topLeft' => options[:border_radius],
                'bottomLeft' => options[:border_radius],
                'topRight' => options[:border_radius],
                'bottomRight' => options[:border_radius]
              }
            elsif is_first
              {
                'topLeft' => options[:border_radius],
                'bottomLeft' => options[:border_radius],
                'topRight' => 0,
                'bottomRight' => 0
              }
            elsif is_last
              {
                'topLeft' => 0,
                'bottomLeft' => 0,
                'topRight' => options[:border_radius],
                'bottomRight' => options[:border_radius]
              }
            else
              0
            end

          {
            label: labels[i] || labels.first,
            data: [value],
            'borderRadius' => border_radius
          }
        end,
        colors: colors
      },
      'legendPosition' => options[:legend_position],
      'tooltipEnabled' => options[:tooltip_enabled]
    }

    render('shared/components/chart', type: SUPPORTED_CHART_TYPES[:stacked_bar], data_payload:)
  end
end
