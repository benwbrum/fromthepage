class RenameDisambiguatorToShortSummaryInArticles < ActiveRecord::Migration[6.1]
  def change
    rename_column :articles, :disambiguator, :short_summary
  end
end
