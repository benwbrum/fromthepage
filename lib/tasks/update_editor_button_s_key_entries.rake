namespace :editor_button do
    desc "Update all rows with key = 's' to 'strike'"
    task update_s_to_strike: :environment do
      EditorButton.where(key: "s").update_all(key: "strike")
    end
end
