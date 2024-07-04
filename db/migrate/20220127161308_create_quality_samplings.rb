class CreateQualitySamplings < ActiveRecord::Migration[5.0]

  def change
    create_table :quality_samplings do |t|
      t.decimal :percent
      t.timestamp :start_time
      t.timestamp :previous_start
      t.references :user, null: false, foreign_key: true
      t.references :collection, null: false, foreign_key: true
      t.text :field, limit: 16.megabytes - 1

      t.timestamps
    end
  end

end
