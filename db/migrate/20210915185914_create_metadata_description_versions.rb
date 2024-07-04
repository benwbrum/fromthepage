class CreateMetadataDescriptionVersions < ActiveRecord::Migration[5.0]

  def change
    create_table :metadata_description_versions do |t|
      t.text :metadata_description
      t.references :user, null: false, foreign_key: true
      t.references :work, null: false, foreign_key: true
      t.integer :version_number

      t.timestamps
    end
  end

end
