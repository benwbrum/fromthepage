class AddTranslationInstructionsToWork < ActiveRecord::Migration[5.2]
  def change
    add_column :works, :translation_instructions, :text
  end
end
