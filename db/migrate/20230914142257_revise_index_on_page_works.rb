class ReviseIndexOnPageWorks < ActiveRecord::Migration[6.0]
  def change
    # remove_index :pages, [:status, :work_id]
    order = ENV['DESC_INDEX_UNSUPPORTED'] == 'true' ? :asc : :desc
    add_index :pages, [:status, :work_id, :edit_started_at], order: { edit_started_at: order }
  end
end
