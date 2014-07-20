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
      log_transcript_attempt
      begin
        if @page.save
          log_transcript_success
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
          log_transcript_error
          flash[:error] = @page.errors[:base].join('<br />')
          render :action => 'display_page'
        end
      rescue => ex
        log_transcript_exception(ex)
        raise ex
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
  def log_transcript_attempt
    # we have access to @page, @user, and params
    @transcript_date = Time.now
    log_message = "TRANSCRIPTION\t#{@transcript_date}\n"
    log_message << "TRANSCRIPTION\tUser\tID: #{current_user.id}\tEmail: #{current_user.email}\tDisplay Name: #{current_user.display_name}\n"
    log_message << "TRANSCRIPTION\tCollection\tID: #{@collection.id}\tTitle:#{@collection.title}\tOwner Email: #{@collection.owner.email}\n"
    log_message << "TRANSCRIPTION\tWork\tID: #{@work.id}\tTitle: #{@work.title}\n"
    log_message << "TRANSCRIPTION\tPage\tID: #{@page.id}\tPosition: #{@page.position}\tTitle:#{@page.title}\n"
    log_message << "TRANSCRIPTION\tSource Text:\nBEGIN_SOURCE_TEXT\n#{params[:page][:source_text]}\nEND_SOURCE_TEXT\n\n"

    logger.info(log_message)
  end

  def log_transcript_exception(ex)
    log_message = "TRANSCRIPTION\t#{@transcript_date}\tERROR\tEXCEPTION\t"
    logger.error(log_message + ex.message)

  end

  def log_transcript_error
    log_message = "TRANSCRIPTION\t#{@transcript_date}\tERROR\t"
    logger.info(@page.errors[:base].join("\t#{log_message}"))
    
  end
  def log_transcript_success
    log_message = "TRANSCRIPTION\t#{@transcript_date}\tSUCCESS\t"
    logger.info(log_message)
    
  end

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
