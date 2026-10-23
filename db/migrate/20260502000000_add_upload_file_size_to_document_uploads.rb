class AddUploadFileSizeToDocumentUploads < ActiveRecord::Migration[7.2]
  def change
    add_column :document_uploads, :upload_file_size, :bigint
  end
end
