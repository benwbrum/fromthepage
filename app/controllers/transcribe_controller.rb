class TranscribeController  < ApplicationController

  include AbstractXmlController
  include DisplayHelper

  require 'rexml/document'
  include Magick
  before_filter :authorized?, :except => :zoom
  protect_from_forgery :except => [:zoom, :unzoom]

  def authorized?
    unless user_signed_in? && current_user.can_transcribe?(@work)
      redirect_to new_user_session_path
    end
  end

  def display_page
    @auto_fullscreen = cookies[:auto_fullscreen] || 'no';
    @layout_mode = cookies[:transcribe_layout_mode] || 'ltr';
  end

  def mark_page_blank
    @page.status = Page::STATUS_BLANK
    @page.save
    @work.work_statistic.recalculate if @work.work_statistic
    redirect_to :controller => 'display', :action => 'display_page', :page_id => @page.id
  end

  def save_transcription
    old_link_count = @page.page_article_links.count
    @page.attributes = params[:page]
    if params['save']
      log_transcript_attempt
      begin
        if @page.save
          log_transcript_success
          if (@page.status == 'raw_ocr') || (@page.status == 'part_ocr')
            record_correction_deed
          else
            record_deed
          end
          # use the new links to blank the graphs
          @page.clear_article_graphs

          new_link_count = @page.page_article_links.count
          logger.debug("DEBUG old_link_count=#{old_link_count}, new_link_count=#{new_link_count}")
          if old_link_count == 0 && new_link_count > 0
            record_index_deed
          end
          @work.work_statistic.recalculate if @work.work_statistic
          @page.submit_background_processes
          redirect_to :action => 'assign_categories', :page_id => @page.id
        else
          log_transcript_error
          flash[:error] = @page.errors[:base].join('<br />')
          render :action => 'display_page'
        end
      rescue REXML::ParseException => ex
        log_transcript_exception(ex)
        flash[:error] =
          "There was an error parsing the mark-up in your transcript.
           This kind of error often occurs if an angle bracket is missing or if an HTML tag is left open.
           Check any instances of < or > symbols in your text.  (The parser error was: #{ex.message})"
        logger.fatal "\n\n#{ex.class} (#{ex.message}):\n"
        render :action => 'display_page'
        flash[:error] = nil
        # raise ex
      rescue  => ex
        log_transcript_exception(ex)
        flash[:error] = ex.message
        logger.fatal "\n\n#{ex.class} (#{ex.message}):\n"
        render :action => 'display_page'
        flash[:error] = nil
        # raise ex
      end
    elsif params['preview']
      @preview_xml = @page.generate_preview
      render :action => 'display_page'
    elsif params['edit']
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

  def translate
  end

  def save_translation
    old_link_count = @page.page_article_links.count
    @page.attributes=params[:page]
    if params['save']
      log_translation_attempt
      begin
        if @page.save
          log_translation_success
          record_translation_deed

          @work.work_statistic.recalculate if @work.work_statistic
          @page.submit_background_processes

          redirect_to :action => 'display_page', :controller => 'display', :page_id => @page.id, :translation => true
        else
          log_translation_error
          flash[:error] = @page.errors[:base].join('<br />')
          render :action => 'translate'
        end
      rescue REXML::ParseException => ex
        log_translation_exception(ex)
        flash[:error] =
          "There was an error parsing the mark-up in your translation.
           This kind of error often occurs if an angle bracket is missing or if an HTML tag is left open.
           Check any instances of < or > symbols in your text.  (The parser error was: #{ex.message})"
        logger.fatal "\n\n#{ex.class} (#{ex.message}):\n"
        render :action => 'translate'
        flash[:error] = nil
        # raise ex
      rescue  => ex
        log_translation_exception(ex)
        flash[:error] = ex.message
        logger.fatal "\n\n#{ex.class} (#{ex.message}):\n"
        render :action => 'translate'
        flash[:error] = nil
        # raise ex
      end
    elsif params['preview']
      @preview_xml = @page.wiki_to_xml(@page.source_translation)
      render :action => 'translate'
    end
  end

protected

  TRANSLATION="TRANSLATION"
  TRANSCRIPTION="TRANSCRIPTION"

  def log_attempt(attempt_type, source_text)
    # we have access to @page, @user, and params
    @transcript_date = Time.now
    log_message = "#{attempt_type}\t#{@transcript_date}\n"
    log_message << "#{attempt_type}\tUser\tID: #{current_user.id}\tEmail: #{current_user.email}\tDisplay Name: #{current_user.display_name}\n"
    log_message << "#{attempt_type}\tCollection\tID: #{@collection.id}\tTitle:#{@collection.title}\tOwner Email: #{@collection.owner.email}\n"
    log_message << "#{attempt_type}\tWork\tID: #{@work.id}\tTitle: #{@work.title}\n"
    log_message << "#{attempt_type}\tPage\tID: #{@page.id}\tPosition: #{@page.position}\tTitle:#{@page.title}\n"
    log_message << "#{attempt_type}\tSource Text:\nBEGIN_SOURCE_TEXT\n#{source_text}\nEND_SOURCE_TEXT\n\n"

    logger.info(log_message)
  end

  def log_exception(attempt_type, ex)
    log_message = "#{attempt_type}\t#{@transcript_date}\tERROR\tEXCEPTION\t"
    logger.error(log_message + ex.message)
    logger.error(ex.backtrace.join("\n"))
  end

  def log_error(attempt_type)
    log_message = "#{attempt_type}\t#{@transcript_date}\tERROR\t"
    logger.info(@page.errors[:base].join("\t#{log_message}"))
  end

  def log_success(attempt_type)
    log_message = "#{attempt_type}\t#{@transcript_date}\tSUCCESS\t"
    logger.info(log_message)
  end


  def log_transcript_attempt
    # we have access to @page, @user, and params
    log_attempt(TRANSCRIPTION, params[:page][:source_text])
  end

  def log_transcript_exception(ex)
    log_exception(TRANSCRIPTION, ex)
  end

  def log_transcript_error
    log_error(TRANSCRIPTION)
  end

  def log_transcript_success
    log_success(TRANSCRIPTION)
  end

  def log_translation_attempt
    # we have access to @page, @user, and params
    log_attempt(TRANSLATION, params[:page][:source_translation])
  end

  def log_translation_exception(ex)
    log_exception(TRANSLATION, ex)
  end

  def log_translation_error
    log_error(TRANSLATION)
  end

  def log_translation_success
    log_success(TRANSLATION)
  end


  def record_deed
    deed = stub_deed
    current_version = @page.page_versions[0]
    if current_version.page_version > 1
      deed.deed_type = Deed::PAGE_EDIT
    else
      deed.deed_type = Deed::PAGE_TRANSCRIPTION
    end
    deed.save!
  end

  def stub_deed
    deed = Deed.new
    deed.note = @note
    deed.page = @page
    deed.work = @work
    deed.collection = @collection
    deed.user = current_user

    deed
  end

  def record_correction_deed
    deed = stub_deed
    deed.deed_type = Deed::OCR_CORRECTED
    deed.save!
  end

  def record_index_deed
    deed = stub_deed
    deed.deed_type = Deed::PAGE_INDEXED
    deed.save!
  end

  def record_translation_deed
    deed = stub_deed
    if @page.page_versions.size < 2 || @page.page_versions.second.source_translation.blank?
      deed.deed_type = Deed::PAGE_TRANSLATED
    else
      deed.deed_type = Deed::PAGE_TRANSLATION_EDIT
    end
    deed.save!
  end
end
