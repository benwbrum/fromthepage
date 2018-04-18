class CreateForosMigration < ActiveRecord::Migration
  def change
    create_table :foros do |f|
      f.belongs_to :user
      f.references :element, :polymorphic => true
      f.timestamps
    end
  end
end
