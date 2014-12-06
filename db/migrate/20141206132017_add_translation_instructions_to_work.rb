class AddTranslationInstructionsToWork < ActiveRecord::Migration
  def change
    add_column :works, :translation_instructions, :text
  end
end
