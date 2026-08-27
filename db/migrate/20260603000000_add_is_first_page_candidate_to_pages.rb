class AddIsFirstPageCandidateToPages < ActiveRecord::Migration[6.1]
  def change
    add_column :pages, :is_first_page_candidate, :boolean, default: nil
  end
end
