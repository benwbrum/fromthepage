class Admin::Ai::DashboardController < Admin::Ai::BaseController
  def index
    redirect_to admin_ai_suspicious_behaviors_path
  end
end
