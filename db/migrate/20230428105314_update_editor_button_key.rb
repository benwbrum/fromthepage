class UpdateEditorButtonKey < ActiveRecord::Migration[6.0]

  def up
    EditorButton.where(key: 's').update_all(key: 'strike')
  end

  def down
    EditorButton.where(key: 'strike').update_all(key: 's')
  end

end
