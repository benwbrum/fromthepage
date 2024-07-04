class DeleteStillEditingAhoyEvents < ActiveRecord::Migration[5.0]

  def change
    Ahoy::Event.where(name: 'transcribe#still_editing').delete_all
  end

end
