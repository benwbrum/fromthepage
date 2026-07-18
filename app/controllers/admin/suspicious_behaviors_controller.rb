class Admin::SuspiciousBehaviorsController < AdminController
  def index
    redirect_to admin_ai_suspicious_behaviors_path, status: :moved_permanently
  end

  def show
    redirect_to admin_ai_suspicious_behavior_path(params[:id]), status: :moved_permanently
  end
end
