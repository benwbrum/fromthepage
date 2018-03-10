class CreateContributions < ActiveRecord::Migration
  def change
    create_table :contributions do |t|
      t.string :type
      t.string :text
      t.belongs_to :mark, index: true

      t.integer :cached_weighted_score, default: 0
      
      t.timestamps
    end
  end
end
