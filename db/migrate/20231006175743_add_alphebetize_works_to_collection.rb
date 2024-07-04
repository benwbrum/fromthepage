class AddAlphebetizeWorksToCollection < ActiveRecord::Migration[6.0]

  def change
    add_column :collections, :alphabetize_works, :boolean, default: true
  end

end
