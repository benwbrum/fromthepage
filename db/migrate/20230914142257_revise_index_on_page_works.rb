class ReviseIndexOnPageWorks < ActiveRecord::Migration[6.0]
  def change
    # remove_index :pages, [:status, :work_id]
    add_index :pages, [ :status, :work_id, :edit_started_at ], order: { edit_started_at: :desc }
  end
end
