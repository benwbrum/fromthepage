class PageVersionController < ApplicationController
  prepend_before_action :authenticate_registered_or_guest_user!
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

  def revert
    unless current_user.like_owner?(@work)
      flash[:error] = t('.not_authorized')
      redirect_to collection_page_version_path(@collection.owner, @collection, @work, @page)
      return
    end

    version = @selected_version

    if version.nil?
      flash[:error] = t('.version_not_found')
      redirect_to collection_page_version_path(@collection.owner, @collection, @work, @page)
      return
    end

    Current.user = current_user
    @page.update!(
      source_text: version.transcription,
      xml_text: version.xml_transcription,
      title: version.title,
      source_translation: version.source_translation,
      xml_translation: version.xml_translation,
      status: version.status
    )

    flash[:notice] = t('.reverted')
    redirect_to collection_transcribe_page_path(@collection.owner, @collection, @work, @page)
  end

  private

  def authenticate_registered_or_guest_user!
    return if current_user.present?

    authenticate_user!
  end
end
