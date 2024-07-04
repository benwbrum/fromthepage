class AddApprovalDeltaToPages < ActiveRecord::Migration[6.0]

  def change
    add_column :pages, :approval_delta, :float
  end

end
