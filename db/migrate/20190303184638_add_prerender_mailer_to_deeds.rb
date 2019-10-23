class AddPrerenderMailerToDeeds < ActiveRecord::Migration[5.2]
  def change
    add_column :deeds, :prerender_mailer, :string, :limit => 2047
  end
end
