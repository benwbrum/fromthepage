class CreateHoneypotVisitsTable < ActiveRecord::Migration[6.1]
  def change
    create_table :honeypot_visits do |t|
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
end
