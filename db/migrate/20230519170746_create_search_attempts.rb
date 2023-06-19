class CreateSearchAttempts < ActiveRecord::Migration[6.0]
  def change
    create_table :search_attempts do |t|
      t.string :query
      t.integer :hits, default: 0
      t.integer :clicks, default: 0
      t.integer :contributions, default: 0
      t.integer :ahoy_visit_id
    end
  end
end
