class ContactController < ApplicationController
  include ContactHelper


  def send_email
    binding.pry
    render

    unless params[email_param].blank?
      ContactMailer.contact(
        first_name: params[:first_name],
        last_name:  params[:last_name],
        email:      params[email_param],
        reason:     params[:reason],
        more:       params[:more]
      ).deliver!
    end
  end
end
