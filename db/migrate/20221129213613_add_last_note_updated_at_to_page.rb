class AddLastNoteUpdatedAtToPage < ActiveRecord::Migration[6.0]
  def change
    add_column :pages, :last_note_updated_at, :datetime

    Page.joins(:notes).each do |page|
      page.update_column(:last_note_updated_at, page.notes.last.updated_at)
    end
  end
end
