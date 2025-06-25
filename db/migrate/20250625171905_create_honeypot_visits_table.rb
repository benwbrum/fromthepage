class CreateHoneypotVisitsTable < ActiveRecord::Migration[6.1]
  def up
    create_table :honeypot_visits do |t|
      t.references :visit,    null: true, foreign_key: true, type: :integer
      t.string   :ip_address, null: false
      t.string   :ip_subnet,  null: false
      t.string   :browser
      t.text     :user_agent

      t.index [:ip_subnet, :created_at]
      t.index [:ip_address]
      t.index [:browser]

      t.timestamps
    end
  end

  def down
    drop_table :honeypot_visits
  end
end
