module ClientperfHelper
  def chart_for(data)
    if encoded = chart_data(data)
      image_tag("http://chart.apis.google.com/chart?cht=ls&chs=300x100&chm=B,e6f2fa,0,0,0|R,000000,0,0.998,1.0&chco=0f7fcf&chxt=r&chd=s:#{encoded}")
    else
      content_tag('p', "no data for this chart")
    end
  end
  
  private
  
  def chart_data(args)
    data, max = args
    return nil if max == 0 || data.size == 0
    max += max * 0.1
    encode = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'

    encoded = data.map do |result|
      char = 62 * result[1] / max.to_f
      encode[char.round,1]
    end.join
    max_in_seconds = number_with_precision(max/ 1000.to_f, 2)
    half_in_seconds = number_with_precision(max/ 2000.to_f, 2)
    "#{encoded}&chxl=0:|0s|#{half_in_seconds}s|#{max_in_seconds}s"
  end
end