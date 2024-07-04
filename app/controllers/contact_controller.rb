class ContactController < ApplicationController

  include ApplicationHelper
  include ContactHelper

  def form
    return unless contact_form_token.to_s != params[:token]

    raise ActionController::RoutingError, 'Not Found'
  end

  def send_email
    render
    return if params[email_param].blank?

    ContactMailer.contact(
      first_name: params[:first_name],
      last_name: params[:last_name],
      email: params[email_param],
      reason: params[:reason],
      more: params[:more]
    ).deliver!
  end

end
