class CreateTitledImages < ActiveRecord::Migration
  def self.up
=begin    create_table :titled_images do |t|
      t.column :original_file,  :string, :limit => 255, :null => false
      t.column :title_seed,     :string, :limit => 20
      t.column :title_override, :string, :limit => 255
      t.column :title,          :string, :limit => 255
      # small image status information
      t.column :shrink_completed,   :boolean, :default => false
      t.column :rotate_completed,   :boolean, :default => false
      t.column :crop_completed,     :boolean, :default => false
      # foreign key to image set
      t.column :image_set_id,   :integer
      # acts as fun
      t.column :position, :integer
      t.column :created_on, :datetime
    end
=end  
  end

  def self.down
#    drop_table :titled_images
  end
end
