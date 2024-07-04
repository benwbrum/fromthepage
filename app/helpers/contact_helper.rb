module ContactHelper

  def email_param
    token = contact_form_token
    :"email_#{token}"
  end

end
