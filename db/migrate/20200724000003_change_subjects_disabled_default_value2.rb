class ChangeSubjectsDisabledDefaultValue2 < ActiveRecord::Migration[5.0]

  def change
    change_column :collections, :subjects_disabled, :boolean, default: true
  end

end
