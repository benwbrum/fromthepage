class TranscribeController  < ApplicationController

  include AbstractXmlController
  include DisplayHelper

  require 'rexml/document'
  include Magick
  before_filter :authorized?, :except => [:zoom, :guest]
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

  def guest
  end

  def mark_page_blank
    #if page is marked blank from overview page, set the source to blank 
    #to allow the pages to be properly counted in statistics
    if params[:source_text] == 'blank'
      @page.source_text = ""
      @page.source_translation = ""
    end
    #if page is marked blank with checkbox, this applies
    if params[:mark_blank] == 'yes'
      @page.status = Page::STATUS_BLANK
      @page.save
      @work.work_statistic.recalculate if @work.work_statistic
      redirect_to :controller => 'display', :action => 'display_page', :page_id => @page.id
    elsif params[:mark_blank] == 'no'
      @page.status = nil
      @page.save
      @work.work_statistic.recalculate if @work.work_statistic
      redirect_to :controller => 'transcribe', :action => 'display_page', :page_id => @page.id
    else
      redirect_to :controller => 'transcribe', :action => 'display_page', :page_id => @page.id
    end
  end

  def needs_review
    if params[:page]['needs_review'] == '1'
      @page.status = Page::STATUS_NEEDS_REVIEW
      record_review_deed
    else
      @page.status = nil
    end
  end

  def save_transcription
    old_link_count = @page.page_article_links.count
    @page.attributes = params[:page]
    #if page has been marked blank, call the mark_blank code
    if params['mark_blank'].present?
      mark_page_blank
      return
    end

    #check to see if the page needs to be marked as needing review
    needs_review

    if params['save']
      log_transcript_attempt
      #leave the status alone if it's needs review, but otherwise set it to transcribed
      unless @page.status == Page::STATUS_NEEDS_REVIEW
        @page.status = Page::STATUS_TRANSCRIBED
      end
      begin
        if @page.save
          log_transcript_success
          if @page.work.ocr_correction
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
          if new_link_count > 0 && @page.status != Page::STATUS_NEEDS_REVIEW
            @page.update_columns(status: Page::STATUS_INDEXED)
          end
          @work.work_statistic.recalculate if @work.work_statistic
          @page.submit_background_processes
      
          #if this is a guest user, force them to sign up after three saves
          if current_user.guest?
            deeds = Deed.where(user_id: current_user.id).count
            if deeds < 3
              flash[:notice] = "You may save up to three transcriptions as a guest."
            else
              redirect_to new_user_registration_path, :resource => current_user
              return
            end
          end

          redirect_to :action => 'assign_categories', :page_id => @page.id
        else
          log_transcript_error
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
        flash.clear
        # raise ex
      rescue  => ex
        log_transcript_exception(ex)
        flash[:error] = ex.message
        logger.fatal "\n\n#{ex.class} (#{ex.message}):\n"
        render :action => 'display_page'
        flash.clear
        # raise ex
      end
    elsif params['preview']
      @preview_xml = @page.wiki_to_xml(@page.source_text, "transcription")

#      @preview_xml = @page.generate_preview("transcription")
      render :action => 'display_page'
    elsif params['edit']
      render :action => 'display_page'
    elsif params['autolink']
      @page.source_text = autolink(@page.source_text)
      render :action => 'display_page'
    end
  end

  def assign_categories
        
    @translation = params[:translation]
    # look for uncategorized articles
    for article in @page.articles
      if article.categories.length == 0
        render :action => 'assign_categories'
        return
      end
    end
    # no uncategorized articles found, skip to display
    if @translation
      redirect_to  :action => 'display_page', :page_id => @page.id, :controller => 'display', :translation => true
    else
      redirect_to  :action => 'display_page', :page_id => @page.id, :controller => 'display'
    end
  end

  def translate
  end

  def save_translation
    old_link_count = @page.page_article_links.count
    @page.attributes=params[:page]

    if params['mark_blank'].present?
      mark_page_blank
      return
    end

    #check to see if the page needs review
    needs_review

    if params['save']
      log_translation_attempt
      #leave the status alone if it's needs review, but otherwise set it to translated

      begin
        if @page.save
          log_translation_success
          record_translation_deed

          @work.work_statistic.recalculate if @work.work_statistic
          @page.submit_background_processes

          #if this is a guest user, force them to sign up after three saves
          if current_user.guest?
            deeds = Deed.where(user_id: current_user.id).count
            if deeds < 3
              flash[:notice] = "You may save up to three transcriptions as a guest."
            else
              redirect_to new_user_registration_path, :resource => current_user
              return
            end
          end
          
          redirect_to :action => 'assign_categories', :page_id => @page.id, :translation => true
        else
          log_translation_error
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
        flash.clear
        # raise ex
      rescue  => ex
        log_translation_exception(ex)
        flash[:error] = ex.message
        logger.fatal "\n\n#{ex.class} (#{ex.message}):\n"
        render :action => 'translate'
        flash.clear
        # raise ex
      end
    elsif params['preview']
      @preview_xml = @page.wiki_to_xml(@page.source_translation, "translation")
      render :action => 'translate'
    elsif params['edit']
      render :action => 'translate'
    elsif params['autolink']
      @page.source_translation = autolink(@page.source_translation)
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

  def record_review_deed
    deed = stub_deed
    deed.deed_type = Deed::NEEDS_REVIEW
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