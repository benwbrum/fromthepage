module ContactHelper

  def email_param
    token = ("#{Time.now.year}#{Time.now.month}#{Time.now.day}".to_i * 32 / 7)
    "email_#{token}".to_sym
  end

end
