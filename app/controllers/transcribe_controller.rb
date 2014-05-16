class TranscribeController  < ApplicationController

  include AbstractXmlController

  require 'rexml/document'
  include Magick
  before_filter :authorized?, :except => :zoom
  protect_from_forgery :except => [:zoom, :unzoom]

  def authorized?
    unless user_signed_in? && current_user.can_transcribe?(@work)
      redirect_to new_user_session_path
    end
  end

  def mark_page_blank
    @page.status = Page::STATUS_BLANK
    @page.save
    @work.work_statistic.recalculate if @work.work_statistic
    redirect_to :controller => 'display', :action => 'display_page', :page_id => @page.id
  end

  def save_transcription
    old_link_count = @page.page_article_links.count
    @page.attributes=params[:page]
    if params['save']
      if @page.save
        record_deed
        # use the new links to blank the graphs
        @page.clear_article_graphs

        new_link_count = @page.page_article_links.count
        logger.debug("DEBUG old_link_count=#{old_link_count}, new_link_count=#{new_link_count}")
        if old_link_count == 0 && new_link_count > 0
          record_index_deed
        end
        @work.work_statistic.recalculate if @work.work_statistic
        #redirect_to :action => 'display_page', :page_id => @page.id, :controller => 'display'
        redirect_to :action => 'assign_categories', :page_id => @page.id
      else
        flash[:error] = @page.errors[:base].join('<br />')
        render :action => 'display_page'
      end
    elsif params['preview']
      @preview_xml = @page.generate_preview
      render :action => 'display_page'
    elsif params['autolink']
      @page.source_text = autolink(@page.source_text)
      render :action => 'display_page'
    end
  end


  def assign_categories
    # look for uncategorized articles
    for article in @page.articles
	  if article.categories.length == 0
	    render :action => 'assign_categories'
	    return
      end
    end
    # no uncategorized articles found, skip to display
    redirect_to  :action => 'display_page', :page_id => @page.id, :controller => 'display'
  end

protected

  def record_deed
    deed = stub_deed
    current_version = @page.page_versions[0]
    if current_version.page_version > 1
      deed.deed_type = Deed::PAGE_EDIT
    else
      deed.deed_type = Deed::PAGE_TRANSCRIPTION
    end
    deed.user = current_user
    deed.save!
  end

  def stub_deed
    deed = Deed.new
    deed.note = @note
    deed.page = @page
    deed.work = @work
    deed.collection = @collection
    deed
  end

  def record_index_deed
    deed = stub_deed
    deed.deed_type = Deed::PAGE_INDEXED
    deed.user = current_user
    deed.save!
  end
end
