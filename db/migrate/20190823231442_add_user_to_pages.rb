class AddUserToPages < ActiveRecord::Migration[5.2]
  def change
    add_reference :pages, :edit_started_by_user, index: true
  end
end
