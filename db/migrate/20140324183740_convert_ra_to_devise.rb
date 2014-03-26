class ConvertRaToDevise < ActiveRecord::Migration
  def change
    #encrypting passwords and authentication related fields
    rename_column :users, "crypted_password", "encrypted_password"
    change_column :users, "encrypted_password", :string, :limit => 128, :default => "", :null => false
    rename_column :users, "salt", "password_salt"
    change_column :users, "password_salt", :string, :default => "", :null => false

    #confirmation related fields
    #rename_column :users, "activation_code", "confirmation_token"
    #rename_column :users, "activated_at", "confirmed_at"
    #change_column :users, "confirmation_token", :string
    #add_column    :users, "confirmation_sent_at", :datetime

    #reset password related fields
    #rename_column :users, "password_reset_code", "reset_password_token"
    add_column :users, "reset_password_token", :string
    add_column :users, "reset_password_sent_at", :datetime

    #rememberme related fields
    add_column :users, "remember_created_at", :datetime #additional field required for devise.

    ## Trackable
    add_column :users, "sign_in_count", :integer, default: 0, null: false
    add_column :users, "current_sign_in_at", :datetime
    add_column :users, "last_sign_in_at", :datetime
    add_column :users, "current_sign_in_ip", :string
    add_column :users, "last_sign_in_ip", :string
  end
end
