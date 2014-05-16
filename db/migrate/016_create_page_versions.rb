class CreatePageVersions < ActiveRecord::Migration
  def self.up
    # add a work version
    add_column :works, :transcription_version, :integer, :default => 0

    create_table :page_versions do |t|
      # state of the page at this version
      t.column :title, :string, :limit => 255
      t.column :transcription, :text
      t.column :xml_transcription, :text

      # foreign keys
      t.column :user_id, :integer
      t.column :page_id, :integer

      # work version info is filled by work.transciption_version
      t.column :work_version, :integer, :default => 0
      t.column :page_version, :integer, :default => 0

      # automated stuff
      t.column :created_on, :datetime
    end
  end

  def self.down
    drop_table :page_versions
    remove_column :works, :transcription_version
  end
end
