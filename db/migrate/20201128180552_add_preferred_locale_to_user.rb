class AddPreferredLocaleToUser < ActiveRecord::Migration[6.0]

  def change
    add_column :users, :preferred_locale, :string
  end

end
