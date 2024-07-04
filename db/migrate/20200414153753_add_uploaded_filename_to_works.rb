class AddUploadedFilenameToWorks < ActiveRecord::Migration[5.0]

  def change
    add_column :works, :uploaded_filename, :string
  end

end
