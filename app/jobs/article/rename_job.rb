class Article::RenameJob < ApplicationJob
  queue_as :default

  # TODO: Exclude user_id for lint checks on unused vars for app/jobs/**/*
  def perform(user_id:, article_id:, old_name:, new_name:, new_article_id: nil)
    Article::Lib::Rename.new(
      article_id: article_id, old_name: old_name, new_name: new_name, new_article_id: new_article_id
    ).call
  end
end
