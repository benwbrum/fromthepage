class AddPagesAreMeaningfulToWork < ActiveRecord::Migration
  def change
    add_column :works, :pages_are_meaningful, :boolean, :default => true
  end
end
