class MasqueradesController < Devise::MasqueradesController
  before_filter :authorized?

  def authorized?
    admin_id = session[session_key]
    admin_user = User.find_by(id: admin_id)
    unless user_signed_in? && admin_user.admin
      cleanup_masquerade_owner_session
      redirect_to dashboard_path
    end
  end

  def show
    super
  end

  def back
    super
  end

  protected
  
  def after_back_masquerade_path_for(resource)
    admin_path
  end

end