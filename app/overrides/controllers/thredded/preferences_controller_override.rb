
Thredded::PreferencesController.class_eval do
  private

  def init_preferences
    @preferences = Thredded::UserPreferencesForm.new(
      user:         thredded_current_user,
      messageboard: messageboard_or_nil,
      messageboards: @collection.messageboard_group.messageboards,
      params: preferences_params
    )
  end

end
