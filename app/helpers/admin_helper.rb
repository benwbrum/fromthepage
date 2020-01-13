module AdminHelper
  def admin_set_title
    case
    when is_active_link?(admin_path, :exclusive)
      content_for :page_title, "Summary - Administration"
    when is_active_link?(admin_user_list_path)
      content_for :page_title, "Users - Administration"
    when is_active_link?(admin_flag_list_path)
      content_for :page_title, "Abuse - Administration"
    when is_active_link?(admin_owner_list_path)
      content_for :page_title, "Owners - Administration"
    when is_active_link?(admin_uploads_path)
      content_for :page_title, "Uploads - Administration"
    when is_active_link?(admin_tail_logfile_path)
      content_for :page_title, "Logfile - Administration"
    when is_active_link?(admin_settings_path)
      content_for :page_title, "Settings - Administration"
    end
  end
end
