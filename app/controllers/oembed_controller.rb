class OembedController < ApplicationController  
  protect_from_forgery with: :null_session
  
  before_action :set_format
  before_action :validate_url
  
  def show
    # Parse the URL to determine what content to embed
    @content_data = parse_url_for_content(params[:url])
    
    if @content_data.nil?
      render json: { error: 'URL not found or not supported' }, status: 404
      return
    end

    response_data = {
      version: "1.0",
      type: "rich",
      provider_name: "FromThePage",
      provider_url: Rails.application.config.provider_url,
      title: @content_data[:title],
      author_name: @content_data[:author],
      author_url: @content_data[:author_url],
      html: embed_html(@content_data),
      width: 600,
      height: 400,
      thumbnail_url: @content_data[:image_url],
      thumbnail_width: 300,
      thumbnail_height: 200
    }

    respond_to do |format|
      format.json { render json: response_data }
      format.xml { render xml: response_data.to_xml(root: 'oembed') }
    end
  end

  private

  def set_format
    # Set format based on format parameter or Accept header
    if params[:format].present?
      request.format = params[:format].to_sym
    elsif request.headers['Accept']&.include?('application/json')
      request.format = :json
    else
      request.format = :xml
    end
  end

  def validate_url
    url = params[:url]
    return head :bad_request if url.blank?
    
    # Ensure the URL is from this domain
    uri = URI.parse(url) rescue nil
    return head :bad_request if uri.nil?
    
    allowed_hosts = [request.host, 'fromthepage.com', 'www.fromthepage.com']
    return head :bad_request unless allowed_hosts.include?(uri.host)
  end

  def parse_url_for_content(url)
    # Parse Rails routes to extract parameters
    begin
      rails_routes = Rails.application.routes.recognize_path(URI.parse(url).path)
    rescue ActionController::RoutingError
      return nil
    end

    case rails_routes[:controller]
    when 'collection'
      if rails_routes[:action] == 'show'
        parse_collection_content(rails_routes)
      end
    when 'display'
      case rails_routes[:action]
      when 'read_work'
        parse_work_content(rails_routes)
      when 'display_page'
        parse_page_content(rails_routes)
      end
    else
      nil
    end
  end

  def parse_collection_content(params)
    collection = Collection.friendly.find(params[:id]) rescue nil
    return nil unless collection&.active?

    base_url = "#{request.protocol}#{request.host_with_port}"
    collection_url = "#{base_url}/#{collection.owner.slug}/#{collection.slug}"
    author_url = "#{base_url}/#{collection.owner.slug}"

    {
      title: collection.title,
      description: view_context.to_snippet(collection.intro_block || "A transcription project on FromThePage", length: 200),
      author: collection.owner.display_name,
      author_url: author_url,
      image_url: view_context.collection_image_url(collection),
      url: collection_url,
      type: 'collection'
    }
  end

  def parse_work_content(params)
    work = Work.friendly.find(params[:work_id]) rescue nil
    return nil unless work&.collection&.active?

    base_url = "#{request.protocol}#{request.host_with_port}"
    work_url = "#{base_url}/#{work.collection.owner.slug}/#{work.collection.slug}/#{work.slug}"
    author_url = "#{base_url}/#{work.collection.owner.slug}"

    {
      title: work.title,
      description: view_context.to_snippet(work.description || "A document in the #{work.collection.title} project", length: 200),
      author: work.collection.owner.display_name,
      author_url: author_url,
      image_url: view_context.work_image_url(work) || view_context.collection_image_url(work.collection),
      url: work_url,
      type: 'work'
    }
  end

  def parse_page_content(params)
    work = Work.friendly.find(params[:work_id]) rescue nil
    return nil unless work&.collection&.active?
    
    page = work.pages.find(params[:page_id]) rescue nil
    return nil unless page

    base_url = "#{request.protocol}#{request.host_with_port}"
    page_url = "#{base_url}/#{work.collection.owner.slug}/#{work.collection.slug}/#{work.slug}/display/#{page.id}"
    author_url = "#{base_url}/#{work.collection.owner.slug}"

    {
      title: "#{work.title} - #{page.title || "Page #{page.position}"}",
      description: view_context.to_snippet(page.source_text || "A page from #{work.title}", length: 200),
      author: work.collection.owner.display_name,
      author_url: author_url,
      image_url: view_context.page_image_url(page) || view_context.work_image_url(work) || view_context.collection_image_url(work.collection),
      url: page_url,
      type: 'page'
    }
  end

  def embed_html(content_data)
    case content_data[:type]
    when 'collection'
      %{<div style="border: 1px solid #ccc; padding: 16px; font-family: Arial, sans-serif; max-width: 600px;">
          <h3 style="margin: 0 0 8px 0;"><a href="#{content_data[:url]}" target="_blank">#{CGI.escapeHTML(content_data[:title])}</a></h3>
          <p style="margin: 0 0 8px 0; color: #666;">#{CGI.escapeHTML(content_data[:description])}</p>
          <p style="margin: 0; font-size: 12px; color: #999;">Transcription project by #{CGI.escapeHTML(content_data[:author])} on FromThePage</p>
        </div>}
    when 'work'
      %{<div style="border: 1px solid #ccc; padding: 16px; font-family: Arial, sans-serif; max-width: 600px;">
          <h3 style="margin: 0 0 8px 0;"><a href="#{content_data[:url]}" target="_blank">#{CGI.escapeHTML(content_data[:title])}</a></h3>
          <p style="margin: 0 0 8px 0; color: #666;">#{CGI.escapeHTML(content_data[:description])}</p>
          <p style="margin: 0; font-size: 12px; color: #999;">Document by #{CGI.escapeHTML(content_data[:author])} on FromThePage</p>
        </div>}
    when 'page'
      %{<div style="border: 1px solid #ccc; padding: 16px; font-family: Arial, sans-serif; max-width: 600px;">
          <h3 style="margin: 0 0 8px 0;"><a href="#{content_data[:url]}" target="_blank">#{CGI.escapeHTML(content_data[:title])}</a></h3>
          <p style="margin: 0 0 8px 0; color: #666;">#{CGI.escapeHTML(content_data[:description])}</p>
          <p style="margin: 0; font-size: 12px; color: #999;">Page transcription by #{CGI.escapeHTML(content_data[:author])} on FromThePage</p>
        </div>}
    end
  end



  def make_absolute_url(url)
    return url if url.blank? || url.start_with?('http')
    "#{request.protocol}#{request.host_with_port}#{url.start_with?('/') ? url : "/#{url}"}"
  end
end