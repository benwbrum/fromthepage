class TranscribeController  < ApplicationController

  include AbstractXmlController
  include DisplayHelper

  require 'rexml/document'
  include Magick
  before_action :authorized?, :except => [:zoom, :guest, :help, :still_editing]
  before_action :active?, :except => [:still_editing]

  protect_from_forgery :except => [:zoom, :unzoom]
  #this prevents failed redirects after sign up
  skip_before_action :store_current_location
  skip_before_action :load_objects_from_params, only: :still_editing
  skip_before_action :load_html_blocks, only: :still_editing
  skip_around_action :switch_locale, only: :still_editing

  def authorized?
    unless user_signed_in? && current_user.can_transcribe?(@work)
      redirect_to new_user_session_path
    end
  end

  def active?
    unless @collection.active?
      redirect_to collection_display_page_path(@collection.owner, @collection, @page.work, @page.id)
    end
  end

  def display_page
    @collection = page.collection unless @collection
    @auto_fullscreen = cookies[:auto_fullscreen] || 'no';
    @layout_mode = cookies[:transcribe_layout_mode] || @collection.default_orientation
    session[:col_id] = @collection.slug
    @current_user_alerted = false
    @field_preview ||= {}
    unless params[:quality_sampling_id].blank?
      @quality_sampling = QualitySampling.find(params[:quality_sampling_id])
    end

    if @page.edit_started_by_user_id != current_user.id &&
       @page.edit_started_at > Time.now - 1.minute
      flash.now[:info] = t('.alert')
      @current_user_alerted = true
    end unless @page.edit_started_at.nil?
  end

  def guest
  end

  def mark_page_blank(options = { redirect: 'display' })
    redirect_path = case options[:redirect]
      when 'transcribe'
        collection_transcribe_page_path(@collection.owner, @collection, @page.work, @page.id)
      else
        collection_display_page_path(@collection.owner, @collection, @page.work, @page.id)
      end

    if params[:page]['mark_blank'] == '1'
      @page.status = Page::STATUS_BLANK
      @page.translation_status = Page::STATUS_BLANK
      @page.save
      record_deed(DeedType::PAGE_MARKED_BLANK)
      @work.work_statistic.recalculate({type: 'blank'}) if @work.work_statistic
      flash[:notice] = t('.saved_notice')
      redirect_to redirect_path 
      return false
    elsif @page.status == Page::STATUS_BLANK && params[:page]['mark_blank'] == '0'
      @page.status = nil
      @page.translation_status = nil
      @page.save
      @work.work_statistic.recalculate({type: 'blank'}) if @work.work_statistic
      flash[:notice] = t('.saved_notice')
      redirect_to redirect_path
      return false
    else
      return true
    end
  end

  def needs_review
    if params[:type] == 'translation'
      if @page.work.collection.review_workflow == true && @page.translation_status == nil
        @page.translation_status = Page::STATUS_NEEDS_REVIEW
        record_deed(DeedType::TRANSLATION_REVIEW)
      elsif params[:page]['needs_review'] == '1'
        unless @page.translation_status == Page::STATUS_NEEDS_REVIEW
          @page.translation_status = Page::STATUS_NEEDS_REVIEW
          record_deed(DeedType::TRANSLATION_REVIEW)
        end
      else
        if @page.translation_status == Page::STATUS_NEEDS_REVIEW
          @page.translation_status = nil
          record_deed(DeedType::TRANSLATION_REVIEWED)
        end
        return
      end
    elsif params['save_to_needs_review']
      unless @page.status == Page::STATUS_NEEDS_REVIEW
        # don't log a deed if the page was already in needs review
        @page.status = Page::STATUS_NEEDS_REVIEW
        record_deed(DeedType::NEEDS_REVIEW)
      end
    else
      if params[:page]['needs_review'] == '1'        
        unless @page.status == Page::STATUS_NEEDS_REVIEW
          @page.status = Page::STATUS_NEEDS_REVIEW
          record_deed(DeedType::NEEDS_REVIEW)
        end
        #if @page.translation_status == 'blank'
        #  @page.translation_status = nil
        #end
      else
        if @page.status == Page::STATUS_NEEDS_REVIEW
          @page.status = nil
          record_deed(DeedType::PAGE_REVIEWED)
          return
        end
      end
    end
  end

  def save_transcription
    old_link_count = @page.page_article_links.where(text_type: 'transcription').count

    unless params[:quality_sampling_id].blank?
      @quality_sampling = QualitySampling.find(params[:quality_sampling_id])
    end

    if @page.field_based
      @field_cells = request.params[:fields]
      table_cells = @page.process_fields(@field_cells)
    end

    @page.attributes = page_params unless page_params.empty?
    #if page has been marked blank, call the mark_blank code 
    unless params[:page]['needs_review'] == '1'
      mark_page_blank(redirect: 'transcribe') or return
    end
    #check to see if the page needs to be marked as needing review
    needs_review
    if params['save'] || params['save_to_incomplete'] || params['save_to_needs_review'] || params['save_to_transcribed'] || params['approve_to_transcribed']
      message = log_transcript_attempt
      #leave the status alone if it's needs review, but otherwise set it to transcribed

      if params['save_to_incomplete'] && params[:page]['needs_review'] != '1' 
        @page.status = Page::STATUS_INCOMPLETE
      elsif params['save_to_needs_review']
        @page.status = Page::STATUS_NEEDS_REVIEW
      elsif (params['save_to_transcribed'] && params[:page]['needs_review'] != '1') || params['approve_to_transcribed']
        @page.status = Page::STATUS_TRANSCRIBED
      else
        # old code; possibly dead
        unless @page.status == Page::STATUS_NEEDS_REVIEW
          @page.status = Page::STATUS_TRANSCRIBED
        end
      end

      begin
        if @page.save
          if @page.field_based && !table_cells.empty?
            @page.replace_table_cells(table_cells)
          end

          log_transcript_success
          flash[:notice] = t('.saved_notice')
          if @page.work.ocr_correction
            record_deed(DeedType::OCR_CORRECTED)
          else
            if @page.source_text_previously_changed?
              record_transcription_deed
            end
          end
          #don't reset subjects if they're disabled
          unless @page.collection.subjects_disabled || (@page.source_text.include?("[[") == false)
            # use the new links to blank the graphs
            @page.clear_article_graphs

            new_link_count = @page.page_article_links.where(text_type: 'transcription').count
            logger.debug("DEBUG old_link_count=#{old_link_count}, new_link_count=#{new_link_count}")
            if old_link_count == 0 && new_link_count > 0
              record_deed(DeedType::PAGE_INDEXED)
            end
            if new_link_count > 0 && @page.status != Page::STATUS_NEEDS_REVIEW && @page.status != Page::STATUS_INCOMPLETE
              @page.update_columns(status: Page::STATUS_INDEXED)
            end
          end
          @work.work_statistic.recalculate({type: @page.status}) if @work.work_statistic
          @page.submit_background_processes("transcription")

          #if this is a guest user, force them to sign up after three saves
          if current_user.guest?
            deeds = Deed.where(user_id: current_user.id).where(deed_type: DeedType.edited_and_transcribed_pages).count
            if deeds < GUEST_DEED_COUNT
              flash[:notice] = t('.you_may_save_notice', guest_deed_count: GUEST_DEED_COUNT)
            else
              session[:user_return_to]=collection_transcribe_page_path(@collection.owner, @collection, @work, @page.id)
              redirect_to new_user_registration_path, :resource => current_user
              return
            end
          end
          if params[:flow] == 'one-off' && @page.status != Page::STATUS_NEEDS_REVIEW
            redirect_to collection_one_off_list_path(@collection.owner, @collection)
          elsif params[:flow] =~ /user-contributions/ && @page.status != Page::STATUS_NEEDS_REVIEW
            user_slug = params[:flow].sub('user-contributions ', '')
            redirect_to collection_user_contribution_list_path(@collection.owner, @collection, user_slug)       
          elsif @quality_sampling
            next_page = @quality_sampling.next_unsampled_page
            if next_page
              redirect_to collection_sampling_review_page_path(@collection.owner, @collection, @quality_sampling, next_page.id, flow: "quality-sampling")            
            else
              redirect_to collection_quality_sampling_path(@collection.owner, @collection, @quality_sampling)
            end
          else
            redirect_to :action => 'assign_categories', page_id: @page.id, collection_id: @collection
          end
        else
          log_transcript_error(message)
          render :action => 'display_page'
        end
      rescue REXML::ParseException => ex
        log_transcript_exception(ex, message)
        flash[:error] = t('.error_message', error_message: ex.message)
        logger.fatal "\n\n#{ex.class} (#{ex.message}):\n"
        render :action => 'display_page'
        flash.clear
        # raise ex
      rescue  => ex
        log_transcript_exception(ex, message)
        flash[:error] = ex.message
        logger.fatal "\n\n#{ex.class} (#{ex.message}):\n"
        render :action => 'display_page'
        flash.clear
        # raise ex
      end
    elsif params['preview']
      begin
        @display_context = 'preview'
        @preview_xml = @page.wiki_to_xml(@page, Page::TEXT_TYPE::TRANSCRIPTION)
        if @page.field_based
          # what do we do about the table cells?
          @field_preview = table_cells.group_by { |cell| cell.transcription_field_id }
        end

        display_page
        render :action => 'display_page'
      rescue REXML::ParseException => ex
        flash[:error] = t('.error_message', error_message: ex.message)
        logger.fatal "\n\n#{ex.class} (#{ex.message}):\n"
        render :action => 'display_page'
        flash.clear
      end

    elsif params['edit']
      if @page.field_based
        # what do we do about the table cells?
        @field_preview = table_cells.group_by { |cell| cell.transcription_field_id }
      end
      display_page
      render :action => 'display_page'
    elsif params['autolink']
      autolinked_source_text = autolink(@page.source_text)
      if Page.find(@page.id).source_text != autolinked_source_text
        @page.source_text = autolinked_source_text
        @autolinked_changed = true
      end
      display_page
      render :action => 'display_page'
    end
  end

  def assign_categories
    @text_type = params[:text_type]
    #no reason to check articles if subjects disabled
    unless @page.collection.subjects_disabled
      @unassigned_articles = []

      # Separate translationa and transcription links
      left, right = @page.page_article_links.partition{|x| x.text_type == 'translation' }

      if @text_type == 'translation'
        unassigned_links = left.select{|link| link.article.categories.empty? }
      else
        unassigned_links = right.select{|link| link.article.categories.empty? }
      end
      unless unassigned_links.empty?
        @unassigned_articles = unassigned_links.map{|link| link.article }.uniq
        render :action => 'assign_categories'
        return
      end
    end
    # no uncategorized articles found, skip to display
    if @text_type == 'translation'
      redirect_to collection_translate_page_path(@collection.owner, @collection, @work, @page.id)
    else
      redirect_to collection_transcribe_page_path(@collection.owner, @collection, @work, @page.id)
    end
  end

  def translate
    session[:col_id] = @collection.slug
    @fromImage = cookies[:fromImage] || false
  end

  def save_translation
    old_link_count = @page.page_article_links.where(text_type: 'translation').count
    @page.attributes = page_params

    #check to see if the page is marked blank
    mark_page_blank or return

    #check to see if the page needs review
    needs_review

    if params['save']
      message = log_translation_attempt
      #leave the status alone if it's needs review, but otherwise set it to translated
      unless @page.translation_status == Page::STATUS_NEEDS_REVIEW
        @page.translation_status = Page::STATUS_TRANSLATED
      end
      begin
        if @page.save
          log_translation_success
          record_translation_deed

          unless @page.collection.subjects_disabled || (@page.source_translation.include?("[[") == false)
            new_link_count = @page.page_article_links.where(text_type: 'translation').count
            logger.debug("DEBUG old_link_count=#{old_link_count}, new_link_count=#{new_link_count}")
            if old_link_count == 0 && new_link_count > 0
              record_deed(DeedType::TRANSLATION_INDEXED)
            end
            if new_link_count > 0 && @page.translation_status != Page::STATUS_NEEDS_REVIEW
              @page.update_columns(translation_status: Page::STATUS_INDEXED)
            end
          end

          @work.work_statistic.recalculate({type: @page.translation_status}) if @work.work_statistic
          @page.submit_background_processes("translation")

          #if this is a guest user, force them to sign up after three saves
          if current_user.guest?
            deeds = Deed.where(user_id: current_user.id).where(deed_type: DeedType.edited_and_transcribed_pages).count
            if deeds < GUEST_DEED_COUNT
              flash[:notice] = t('.notice', guest_deed_count: GUEST_DEED_COUNT)
            else
              session[:user_return_to]=collection_translate_page_path(@collection.owner, @collection, @work, @page.id)
              redirect_to new_user_registration_path, :resource => current_user
              return
            end
          end

          redirect_to :action => 'assign_categories', page_id: @page.id, collection_id: @collection, :text_type => 'translation'
        else
          log_translation_error(message)
          render :action => 'translate'
        end
      rescue REXML::ParseException => ex
        log_translation_exception(ex, message)
        flash[:error] = t('.error_message', error_message: ex.message)
        logger.fatal "\n\n#{ex.class} (#{ex.message}):\n"
        render :action => 'translate'
        flash.clear
        # raise ex
      rescue  => ex
        log_translation_exception(ex, message)
        flash[:error] = ex.message
        logger.fatal "\n\n#{ex.class} (#{ex.message}):\n"
        render :action => 'translate'
        flash.clear
        # raise ex
      end
    elsif params['preview']
      @display_context = 'preview'
      @preview_xml = @page.wiki_to_xml(@page, Page::TEXT_TYPE::TRANSLATION)
      translate
      render :action => 'translate'
    elsif params['edit']
      translate
      render :action => 'translate'
    elsif params['autolink']
      @page.source_translation = autolink(@page.source_translation)
      translate
      render :action => 'translate'

    end
  end

  def still_editing
    if current_user
      @page = Page.find(params[:page_id])
      @page.update_columns(edit_started_at: Time.now, edit_started_by_user_id: current_user.id)
      render plain: ''
    else
      render plain: 'session expired', status: 401
    end
  end

  def goto_next_untranscribed_page

    next_page_path = user_profile_path(@work.collection.owner)
    flash[:notice] = t('.notice')

    if @work.next_untranscribed_page
      flash[:notice] = t('.another_page_notice')
      next_page_path = collection_transcribe_page_path(@work.collection.owner, @work.collection, @work, @work.next_untranscribed_page)
    elsif @collection.class == DocumentSet
      docset = @collection
      next_page = docset.find_next_untranscribed_page_for_user(current_user)
      if !next_page.nil?
        flash[:notice] = t('.no_more_pages_notice')
        next_page_path = collection_transcribe_page_path(docset.owner, docset, next_page.work, next_page)
      else # Docset has no more Untranscribed works, bump up to collection level
        next_page = docset.collection.find_next_untranscribed_page_for_user(current_user)
        unless next_page.nil?
          flash[:notice] = t('.no_more_pages_notice')
          next_page_path = collection_transcribe_page_path(docset.collection.owner, docset.collection, next_page.work, next_page)
        end
      end
    else
      next_page = @collection.find_next_untranscribed_page_for_user(current_user)
      unless next_page.nil?
        flash[:notice] = t('.no_more_pages_notice')
        next_page_path = collection_transcribe_page_path(@collection.owner, @collection, next_page.work, next_page)
      end
    end
    redirect_to next_page_path
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
    return log_message
  end

  def log_exception(attempt_type, ex, message)
    log_message = "#{attempt_type}\t#{@transcript_date}\tERROR\tEXCEPTION\t"
    logger.error(log_message + ex.message)
    logger.error(ex.backtrace.join("\n"))
    log_email_error(message, ex)
  end

  def log_error(attempt_type, message)
    log_message = "#{attempt_type}\t#{@transcript_date}\tERROR\t"
    logger.info(@page.errors[:base].join("\t#{log_message}"))
    log_email_error(message, @page.errors[:base])
  end

  def log_success(attempt_type)
    log_message = "#{attempt_type}\t#{@transcript_date}\tSUCCESS\t"
    logger.info(log_message)
  end


  def log_transcript_attempt
    # we have access to @page, @user, and params
    if @page.field_based
      if request.params[:fields].nil?
        source_text = "[NULL FIELD-BASED PARAMS]"
      else
        source_text = request.params[:fields].pretty_inspect
      end
    else
      source_text = params[:page][:source_text]
    end

    log_message = log_attempt(TRANSCRIPTION, source_text)
    return log_message
  end

  def log_transcript_exception(ex, message)
    log_exception(TRANSCRIPTION, ex, message)
  end

  def log_transcript_error(message)
    log_error(TRANSCRIPTION, message)
  end

  def log_transcript_success
    log_success(TRANSCRIPTION)
  end

  def log_translation_attempt
    # we have access to @page, @user, and params
    log_message = log_attempt(TRANSLATION, params[:page][:source_translation])
    return log_message
  end

  def log_translation_exception(ex, message)
    log_exception(TRANSLATION, ex, message)
  end

  def log_translation_error(message)
    log_error(TRANSLATION, message)
  end

  def log_translation_success
    log_success(TRANSLATION)
  end

  def log_email_error(message, ex)
    if SMTP_ENABLED
      begin
        SystemMailer.page_save_failed(message, ex).deliver!
      rescue StandardError => e
        print "SMTP Failed: Exception: #{e.message}"
      end
    end
  end

  def record_transcription_deed
    deed = stub_deed
    current_version = @page.page_versions[0]
    if current_version.page_version > 1
      deed.deed_type = DeedType::PAGE_EDIT
    else
      deed.deed_type = DeedType::PAGE_TRANSCRIPTION
    end
    deed.save!
  end

  def stub_deed
    deed = Deed.new
    deed.note = @note
    deed.page = @page
    deed.work = @work
    if @collection.is_a?(Collection)
      deed.collection = @collection
    else
      deed.collection = @collection.collection
    end
    deed.user = current_user

    deed
  end

  def record_deed(type)
    deed = stub_deed
    deed.deed_type = type
    deed.save!
  end

  def record_translation_deed
    deed = stub_deed
    if @page.page_versions.size < 2 || @page.page_versions.second.source_translation.blank?
      deed.deed_type = DeedType::PAGE_TRANSLATED
    else
      deed.deed_type = DeedType::PAGE_TRANSLATION_EDIT
    end
    deed.save!
  end

  private

  def page_params
    params.require(:page).permit(:source_text, :source_translation, :title)
  end
end
