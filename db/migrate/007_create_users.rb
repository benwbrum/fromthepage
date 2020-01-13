class CreateUsers < ActiveRecord::Migration[5.2]
  def self.up
    create_table "users", :force => true do |t|
      t.column :login,                     :string
      t.column :display_name,              :string
      t.column :print_name,                :string
      t.column :email,                     :string
      t.column :owner,                     :boolean, :default => false
      t.column :admin,                     :boolean, :default => false
      t.column :crypted_password,          :string, :limit => 40
      t.column :salt,                      :string, :limit => 40
      t.column :created_at,                :datetime
      t.column :updated_at,                :datetime
      t.column :remember_token,            :string
      t.column :remember_token_expires_at, :datetime
    end
  end

  def self.down
    drop_table "users"
  end
end
