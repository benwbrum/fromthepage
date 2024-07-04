class AddSsoIssuerToUsers < ActiveRecord::Migration[6.0]

  def change
    add_column :users, :sso_issuer, :string
  end

end
