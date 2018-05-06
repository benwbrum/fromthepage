class CreatePublicationsMigration < ActiveRecord::Migration
  def change
    create_table :publications do |pu|
      pu.belongs_to :user
      pu.belongs_to :foro
      pu.column :parent_id, :integer
      pu.timestamps
      pu.string :text
    end
  end
end
