class ArticleVersionController < ApplicationController
  before_action :set_versions

  def set_versions
    if @article_version.nil? && @article.nil?
      head :bad_request
      return
    end

    return head(:not_found) unless @article && @collection && @collection.articles.exists?(@article.id)

    @selected_version = @article_version.present? ? @article_version : @article.article_versions.first
    @previous_version = @selected_version.prev if @selected_version.present?
  end

  def list
    respond_to do |format|
      format.html { render 'show' }
    end
  end
end
