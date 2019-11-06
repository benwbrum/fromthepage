class MasqueradesController < Devise::MasqueradesController
  before_action :authorized?

  def authorized?
    admin_id = session[session_key]
    admin_user = User.friendly.find_by(id: admin_id)
    unless user_signed_in? && admin_user.admin
      cleanup_masquerade_owner_session
      redirect_to dashboard_path
    end
  end

  def show
    user = User.friendly.find(params[:id])
    self.resource = resource_class.to_adapter.find_first(:id => user.id)

    redirect_to(new_user_session_path) and return unless self.resource
    self.resource.masquerade!
    request.env["devise.skip_trackable"] = "1"

    if Devise.masquerade_bypass_warden_callback
      if respond_to?(:bypass_sign_in)
        bypass_sign_in(self.resource)
      else
        sign_in(self.resource, :bypass => true)
      end
    else
      sign_in(self.resource)
    end

    if Devise.masquerade_routes_back && Rails::VERSION::MAJOR == 5
      redirect_back(fallback_location: "#{after_masquerade_path_for(self.resource)}?#{after_masquerade_path_for(resource)}")
    elsif Devise.masquerade_routes_back && request.env['HTTP_REFERER'].present?
      redirect_back fallback_location: root_path
    else
      redirect_to("#{after_masquerade_path_for(self.resource)}?#{after_masquerade_path_for(resource)}")
    end
  end

  def back
    super
  end

  protected

  def after_back_masquerade_path_for(resource)
    admin_path
  end

end
