class AddCookiesConsentToUsers < ActiveRecord::Migration[7.2]
  def up
    add_column :users, :cookies_consent, :integer, default: 0, null: false
  end

  def down
    remove_column :users, :cookies_consent
  end
end
