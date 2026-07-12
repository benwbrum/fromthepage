class ArticleVersionController < ApplicationController
  prepend_before_action :authenticate_registered_or_guest_user!
  before_action :set_versions
  before_action :noindex_headers

  def set_versions
    @selected_version = @article_version.present? ? @article_version : @article.article_versions.first
    @previous_version = @selected_version.prev if @selected_version.present?
  end

  def list
    render 'show'
  end
end
