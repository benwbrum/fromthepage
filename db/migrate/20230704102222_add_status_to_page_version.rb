class AddStatusToPageVersion < ActiveRecord::Migration[6.0]

  def change
    add_column :page_versions, :status, :string
  end

end
