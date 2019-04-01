class AddPrerenderMailerToDeeds < ActiveRecord::Migration
  def change
    add_column :deeds, :prerender_mailer, :string, :limit => 2047
  end
end
