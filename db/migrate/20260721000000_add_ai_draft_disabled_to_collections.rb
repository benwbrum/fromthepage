# frozen_string_literal: true

class AddAiDraftDisabledToCollections < ActiveRecord::Migration[7.2]
  def change
    add_column :collections, :ai_draft_disabled, :boolean, default: false
  end
end
