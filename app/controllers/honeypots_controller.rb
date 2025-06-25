class HoneypotsController < ApplicationController

  def trap
    record_honeypot_visit

    redirect_to landing_page_path
  end

  private

  def record_honeypot_visit
    ip = request.remote_ip

    HoneypotVisit.create!(
      ip_address: ip,
      ip_subnet: subnet_from_ip(ip),
      browser: browser_name(request.user_agent),
      user_agent: request.user_agent.to_s,
      visit: ahoy.visit
    )
  end

  def subnet_from_ip(ip)
    require 'ipaddr'
    IPAddr.new(ip).mask(16).to_s
  rescue StandardError => _e
    '0.0.0.0/16'
  end

  def browser_name(user_agent)
    ua = user_agent.to_s.downcase
    case
    when ua.include?('chrome')   then 'Chrome'
    when ua.include?('firefox')  then 'Firefox'
    when ua.include?('safari') && !ua.include?('chrome') then 'Safari'
    when ua.include?('edge')     then 'Edge'
    when ua.include?('opera')    then 'Opera'
    when ua.include?('msie') || ua.include?('trident') then 'IE'
    else 'Other'
    end
  end
end
