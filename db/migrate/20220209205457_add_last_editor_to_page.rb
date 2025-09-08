class AddLastEditorToPage < ActiveRecord::Migration[5.0]
  def change
    add_column :pages, :last_editor_user_id, :int, null: true, foreign_key: true

    # Page.all.each do |page|
    # unless page.last_editor_user_id
    #   version = page.current_version
    #   if version
    #     user = version.user
    #     if user
    #       page.update_column(:last_editor_user_id, user.id)
    #     end
    #   end
    # end
    # end

    # reviewed_pages.each do |page|
    #   page.update_column(:last_editor_user_id, page.page_versions.detect{|pv| pv.user_id != page.current_version.user_id}.user_id)
    # end
  end
end
