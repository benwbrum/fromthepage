class MigrateIsPublicBooleanFieldToVisibilityColumnForDocumentSets < ActiveRecord::Migration[6.1]
  def up
    DocumentSet.where(is_public: false).in_batches.update_all(visibility: :private)
  end

  def down
    DocumentSet.where(visibility: [:private, :read_only]).in_batches.update_all(is_public: false)
    DocumentSet.where(visibility: [:public]).in_batches.update_all(is_public: true)
  end
end
