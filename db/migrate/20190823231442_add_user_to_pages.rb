class AddUserToPages < ActiveRecord::Migration
  def change
    add_reference :pages, :edit_started_by_user, index: true
  end
end
