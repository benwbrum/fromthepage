class CreateExternalApiRequests < ActiveRecord::Migration[5.0]

  def change
    create_table :external_api_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.references :collection, null: false, foreign_key: true
      t.references :work, null: true, foreign_key: true
      t.references :page, null: true
      t.string :engine
      t.string :status
      t.text :params

      t.timestamps
    end
  end

end
