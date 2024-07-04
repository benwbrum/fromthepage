# This migration comes from active_storage (originally 20180723000244)
class AddForeignKeyConstraintToActiveStorageAttachmentsForBlobId2 < ActiveRecord::Migration[5.0]

  def up
    return if foreign_key_exists?(:active_storage_attachments, column: :blob_id)

    return unless table_exists?(:active_storage_blobs)

    add_foreign_key :active_storage_attachments, :active_storage_blobs, column: :blob_id
  end

end
