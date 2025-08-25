class AddIndexToPageStatus < ActiveRecord::Migration[5.0]
  def change
    add_index :pages, [ :status, :work_id ]
  end
end
