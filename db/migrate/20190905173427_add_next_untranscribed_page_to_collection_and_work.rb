# frozen_string_literal: true

class AddNextUntranscribedPageToCollectionAndWork < ActiveRecord::Migration
  def change
    add_column :collections, :next_untranscribed_page_id, :integer
    add_column :document_sets, :next_untranscribed_page_id, :integer
    add_column :works, :next_untranscribed_page_id, :integer
  end
end
