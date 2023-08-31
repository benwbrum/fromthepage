class CreateSearchAttempts < ActiveRecord::Migration[5.0]
  def change
    create_table :search_attempts do |t|
      t.timestamps
      t.string :query
      t.integer :hits, default: 0
      t.integer :clicks, default: 0
      t.integer :contributions, default: 0

      t.integer :visit_id, index: true
      t.references :user, null: true
      t.boolean :owner, default: false
    end
  end
end
