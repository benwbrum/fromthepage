class AddSemanticContributionToMark < ActiveRecord::Migration
  def change
    change_table :marks do |t|
      t.belongs_to :semanticContribution
    end
  end
end
