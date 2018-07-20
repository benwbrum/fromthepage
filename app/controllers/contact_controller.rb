class ContactController < ApplicationController
  def send_email
    render

    ContactMailer.contact(
      first_name: params[:first_name],
      last_name:  params[:last_name],
      email:      params[:email],
      reason:     params[:reason],
      more:       params[:more]
    ).deliver!
  end
end
