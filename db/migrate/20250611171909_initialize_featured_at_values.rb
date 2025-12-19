class InitializeFeaturedAtValues < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    Collection.reset_column_information
    DocumentSet.reset_column_information
    User.reset_column_information

    collections = Collection.includes(:owner)
                            .joins(works: :pages)
                            .joins(:owner)
                            .where(owner: { deleted: false })
                            .where(featured_at: nil)
                            .unrestricted.where("LOWER(collections.title) NOT LIKE 'test%'")
                            .distinct
                            .map do |collection|
      collection.featured_at = collection.created_at
      collection
    end

    Collection.import collections, on_duplicate_key_update: [:featured_at], validate: false

    document_sets = DocumentSet.includes(:owner)
                               .joins(works: :pages)
                               .joins(:owner)
                               .where(owner: { deleted: false })
                               .where(featured_at: nil)
                               .unrestricted.where("LOWER(document_sets.title) NOT LIKE 'test%'")
                               .distinct
                               .map do |document_set|
      document_set.featured_at = document_set.created_at
      document_set
    end

    DocumentSet.import document_sets, on_duplicate_key_update: [:featured_at], validate: false
  end
end
