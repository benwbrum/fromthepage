class Admin::Ai::BaseController < AdminController
  def side_nav_tabs
    [
      {
        icon: '#icon-warning-sign',
        name: t('admin.ai.nav.suspicious_behaviors'),
        path: admin_ai_suspicious_behaviors_path,
        selected: :suspicious_behaviors
      },
      {
        icon: '#icon-robot',
        name: t('admin.ai.nav.errors'),
        path: admin_ai_errors_path,
        selected: :errors
      }
    ]
  end
  helper_method :side_nav_tabs
end
