class CreateFlags < ActiveRecord::Migration[5.2]
  def change
    create_table :flags do |t|
      t.references :author_user, index: true
      t.references :page_version, index: true
      t.references :article_version, index: true
      t.references :note, index: true
      t.string :provenance
      t.string :status, index: true, default: Flag::Status::UNCONFIRMED
      t.text :snippet
      t.text :comment
      t.references :reporter_user, index: true
      t.references :auditor_user, index: true
      t.datetime :content_at

      t.timestamps
    end
  end
end
