class CreateDeeds < ActiveRecord::Migration
  def self.up
    create_table :deeds do |t|
      # type key
      t.column :deed_type, :string, :limit => 10
      # associations to just about everything in the system
      t.column :page_id, :integer
      t.column :work_id, :integer
      t.column :collection_id, :integer
      t.column :article_id, :integer
      t.column :user_id, :integer
      t.column :note_id, :integer
      t.timestamps
    end

    # migrate data
    transcriptions = PageVersion.where('page_version=1').all
    transcriptions.each do |pv|
      deed = self.deed_from_version(pv)
      deed.deed_type = Deed::PAGE_TRANSCRIPTION
      deed.save!
    end

    edits = PageVersion.where('page_version>1').all
    edits.each do |pv|
      deed = self.deed_from_version(pv)
      deed.deed_type = Deed::PAGE_EDIT
      deed.save!
    end

    # add indexes
    add_index :deeds,  :article_id
    add_index :deeds,  :page_id
    add_index :deeds,  :work_id
    add_index :deeds,  :collection_id
    add_index :deeds,  :user_id
    add_index :deeds,  :note_id
    add_index :deeds,  :created_at

  end

  def self.down
    drop_table :deeds
  end


  private
  def self.deed_from_version(pv)
    deed = Deed.new
    deed.page_id = pv.page.id
    deed.work_id = pv.page.work.id
    deed.collection_id = pv.page.work.collection.id
    deed.user_id = pv.user.id
    deed.created_at = pv.created_on
    return deed
  end
end
