class AddUploadedFilenameToWorks < ActiveRecord::Migration[6.0]
  def change
    add_column :works, :uploaded_filename, :string
  end
end
