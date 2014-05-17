class CreateIaWorks < ActiveRecord::Migration
  def self.up
    create_table :ia_works do |t|
      # known beforehand
      t.string :detail_url
      t.integer :user_id
      t.integer :work_id #foreign key to FromThePage works

      t.string :server
      t.string :ia_path

      # derivable from metadata.xml
      t.string :book_id
      t.string :title
      t.string :creator
      t.string :collection
      t.string :description
      t.string :subject
      t.string :notes
      t.string :contributor
      t.string :sponsor
      t.string :image_count

      # derived from other fiels
      t.integer :title_leaf


      t.timestamps
    end
  end

  def self.down
    drop_table :ia_works
  end
end
