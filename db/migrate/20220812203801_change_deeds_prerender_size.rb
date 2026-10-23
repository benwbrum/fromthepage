class ChangeDeedsPrerenderSize < ActiveRecord::Migration[6.0]
  def up
    change_column :deeds, :prerender, :string, limit: 8191
    change_column :deeds, :prerender_mailer, :string, limit: 8191
  end
  def down
    change_column :deeds, :prerender, :string, limit: 2047
    change_column :deeds, :prerender_mailer, :string, limit: 2047
  end
end
