class AddPagesAreMeaningfulToWork < ActiveRecord::Migration[5.2]
  def change
    add_column :works, :pages_are_meaningful, :boolean, :default => true
  end
end
