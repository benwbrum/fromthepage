class CreatePages < ActiveRecord::Migration
  def self.up
    create_table :pages do |t|
      # t.column :name, :string
      t.column :title, :string, :limit => 255

      # transcription source (rudimentary for this version)
      t.column :transcription, :text

      # image info
      t.column :base_image, :string, :limit => 255
      t.column :base_width, :integer
      t.column :base_height, :integer
      t.column :shrink_factor, :integer

      # foreign keys
      t.column :work_id, :integer

      # automated stuff
      t.column :created_on, :datetime
      t.column :position, :integer
      t.column :lock_version, :integer, :default => 0
    end
  end

  def self.down
    drop_table :pages
  end
end
