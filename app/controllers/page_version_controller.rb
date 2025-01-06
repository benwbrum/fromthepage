class PageVersionController < ApplicationController

  before_action :set_versions

  def set_versions
    @page_versions = []

    @page.page_versions.each do |version|
      @page_versions << version if version.content_changed?
    end

    @selected_version = @page_version.present? ? @page_version : @page_versions.first
    @previous_version = params[:compare_version_id] ? PageVersion.find(params[:compare_version_id]) : @selected_version&.prev
  end

  def list
    render 'show'
  end

end
