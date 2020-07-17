class ChangeSubjectsDisabledDefaultValue < ActiveRecord::Migration[6.0]
  def change
    change_column :collections, :subjects_disabled, :boolean, default: true
  end
end
