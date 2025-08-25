module ContactHelper
  def email_param
    token = contact_form_token
    "email_#{token}".to_sym
  end
end
