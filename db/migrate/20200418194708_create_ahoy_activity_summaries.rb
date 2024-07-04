class CreateAhoyActivitySummaries < ActiveRecord::Migration[5.0]

  def change
    # drop_table :ahoy_activity_summaries
    create_table :ahoy_activity_summaries do |t|
      t.datetime  :date
      t.integer   :user_id
      t.integer   :collection_id
      t.string    :activity
      t.integer   :minutes
      t.timestamps
    end
    add_index :ahoy_activity_summaries, [:date, :collection_id, :user_id, :activity],
      unique: true,
      name: 'ahoy_activity_day_user_collection'
  end

end
