class ArticleVersionController < ApplicationController

  before_filter :set_versions

  def set_versions
    @selected_version = @article_version.present? ? @article_version : @article.article_versions.first
    @previous_version = @selected_version.prev if @selected_version.present?
  end

  def list
    render 'show'
  end

end