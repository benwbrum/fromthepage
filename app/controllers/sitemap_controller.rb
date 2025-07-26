class SitemapController < ApplicationController
  skip_before_action :store_current_location
  skip_before_action :load_objects_from_params
  skip_before_action :load_html_blocks
  skip_around_action :switch_locale

  def index
    respond_to do |format|
      format.xml do
        @collections = Collection.where(restricted: false, is_active: true)
                                .includes(:owner, works: [:pages])
                                .limit(10000)
        
        render template: 'sitemap/index', layout: false, content_type: 'application/xml'
      end
    end
  end

  def collections
    respond_to do |format|
      format.xml do
        offset = params[:offset].to_i
        @collections = Collection.where(restricted: false, is_active: true)
                                .includes(:owner)
                                .order(:id)
                                .offset(offset)
                                .limit(1000)
        
        render template: 'sitemap/collections', layout: false, content_type: 'application/xml'
      end
    end
  end

  def works
    respond_to do |format|
      format.xml do
        offset = params[:offset].to_i
        @works = Work.joins(:collection)
                     .where(collections: { restricted: false, is_active: true })
                     .includes(:collection => :owner)
                     .order(:id)
                     .offset(offset)
                     .limit(1000)
        
        render template: 'sitemap/works', layout: false, content_type: 'application/xml'
      end
    end
  end

  def pages
    respond_to do |format|
      format.xml do
        offset = params[:offset].to_i
        @pages = Page.joins(work: :collection)
                     .where(collections: { restricted: false, is_active: true })
                     .where.not(status: 'blank')
                     .includes(work: { collection: :owner })
                     .order(:id)
                     .offset(offset)
                     .limit(1000)
        
        render template: 'sitemap/pages', layout: false, content_type: 'application/xml'
      end
    end
  end
end