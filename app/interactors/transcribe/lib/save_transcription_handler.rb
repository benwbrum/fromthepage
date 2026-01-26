class Transcribe::Lib::SaveTranscriptionHandler < Transcribe::Lib::BaseHandler
  include Rails.application.routes.url_helpers

  attr_accessor :page, :notice, :redirect_route, :message

  TRANSLATION = 'TRANSLATION'
  TRANSCRIPTION = 'TRANSCRIPTION'

  def initialize(page:, collection:, page_params:, extra_page_params:, user:, action_params:, field_cells: nil, quality_sampling: nil, ai_draft_used: nil)
    @page = page
    @collection = collection
    @page_params = page_params
    @extra_page_params = extra_page_params
    @action_params = action_params
    @field_cells = field_cells
    @quality_sampling = quality_sampling
    @ai_draft_used = ai_draft_used
    @user = user

    @notice = nil
    @redirect_route = nil
    @message = nil

    super()
  end

  def perform
    precalculate_articles
    calculate_table_cells

    @page.attributes = @page_params unless @page_params.empty?
    @page.ai_draft_used = @ai_draft_used

    @message = log_transcript_attempt

    handle_page_status

    if @page.save
      if @page.ai_draft_used
        record_deed({
          page_id: @page.id,
          work_id: @page.work_id,
          collection_id: @collection.id,
          user_id: @user.id,
          deed_type: DeedType::AI_DRAFT
        })
      end

      log_success(TRANSCRIPTION)
      @notice = I18n.t('transcribe.save_transcription.saved_notice')

      record_transcription_deed
      handle_articles

      @page.work.work_statistic&.recalculate({ type: @page.status })
      @page.submit_background_processes('transcription')

      return if handle_guest_user.present?

      handle_flow
    else
      log_error(TRANSCRIPTION, @message)
    end
  end

  private

  def log_transcript_attempt
    if @page.field_based
      source_text = @field_cells&.pretty_inspect || '[NULL FIELD-BASED PARAMS]'
    else
      source_text = @page_params[:source_text]
    end

    message = log_attempt(TRANSCRIPTION, source_text)
    message
  end

  def action_is_save?
    @action_params[:save_to_incomplete] || @action_params[:save_to_needs_review] ||
      @action_params[:save_to_transcribed]
  end

  def save_to_incomplete?
    @action_params[:save_to_incomplete] || @action_params[:done_to_incomplete]
  end

  def save_to_needs_review?
    @action_params[:save_to_needs_review] || @action_params[:done_to_needs_review]
  end

  def save_to_transcribed?
    @action_params[:save_to_transcribed] || @action_params[:done_to_transcribed]
  end

  def approve_to_transcribed?
    @action_params[:approve_to_transcribed]
  end

  def precalculate_articles
    @old_link_count = @page.page_article_links.where(text_type: 'transcription').count
    @old_article_ids = @page.articles.pluck(:id)
  end

  def calculate_table_cells
    return unless @page.field_based

    @page = TranscriptionField::Lib::Utils.parse_fields(page: @page, field_cells: @field_cells)
  end

  def record_transcription_deed
    deed_type = nil
    if @page.work.ocr_correction
      deed_type = DeedType::OCR_CORRECTED
    elsif @page.source_text_previously_changed?
      deed_type = @page.page_versions.first.page_version > 1 ? DeedType::PAGE_EDIT : DeedType::PAGE_TRANSCRIPTION
    end

    return if deed_type.nil?

    record_deed({
      page_id: @page.id,
      work_id: @page.work_id,
      collection_id: @collection.id,
      user_id: @user.id,
      deed_type: deed_type
    })
  end

  def handle_page_status
    if save_to_incomplete? && @extra_page_params[:needs_review] != '1'
      @page.status = :incomplete
    elsif save_to_needs_review? && @collection.review_workflow
      @page.status = :needs_review
    elsif save_to_needs_review?
      if @extra_page_params[:needs_review] != '1' && Page::COMPLETED_STATUSES.include?(@page.status)
        skip_re_review = @collection.owner == @user ||
          @collection.reviewers.find_by(id: @user.id).present? ||
          Deed.where(deed_type: DeedType::COMPLETED_TYPES, user_id: @user.id, page_id: @page.id).any?

        @page.status = skip_re_review ? :transcribed : :needs_review
      else
        @page.status = @extra_page_params[:needs_review] == '1' ? :needs_review : :transcribed
      end
    elsif (save_to_transcribed? && @extra_page_params[:needs_review] != '1') || approve_to_transcribed?
      @page.status = :transcribed
    else
      @page.status = :transcribed unless @page.status_needs_review?
    end
  end

  def handle_articles
    return if @collection.subjects_disabled || @page.source_text.exclude?('[[')

    @page.clear_article_graphs

    new_link_count = @page.page_article_links.where(text_type: 'transcription').count

    if @old_link_count.zero? && new_link_count.positive?
      record_deed({
        page_id: @page.id,
        work_id: @page.work_id,
        collection_id: @collection.id,
        user_id: @user.id,
        deed_type: DeedType::PAGE_INDEXED
      })
    end

    if new_link_count.positive? &&
      !@page.status_needs_review? &&
      !@page.status_incomplete?

      @page.update_columns(status: Page.statuses[:indexed])
    end
  end

  def handle_guest_user
    return unless @user.guest?

    deeds = Deed.where(user_id: @user.id).where(deed_type: DeedType.edited_and_transcribed_pages).count

    if deeds < GUEST_DEED_COUNT
      @notice = I18n.t('transcribe.save_transcription.you_may_save_notice', guest_deed_count: GUEST_DEED_COUNT)
    else
      Current.session[:user_return_to] = collection_transcribe_page_path(
        @collection.owner, @collection, @page.work, @page.id
      )

      @redirect_route = new_user_registration_path
    end
  end

  def handle_flow
    if @action_params[:flow] == 'one-off' && !@page.status_needs_review?
      @redirect_route = collection_one_off_list_path(@collection.owner, @collection)
    elsif @action_params[:flow] =~ /user-contributions/ && !@page.status_needs_review?
      user_slug = @action_params[:flow].sub('user-contributions ', '')
      @redirect_route = collection_user_contribution_list_path(@collection.owner, @collection, user_slug)
    elsif @quality_sampling.present?
      next_page = @quality_sampling.next_unsampled_page

      if next_page
        @notice = I18n.t('transcribe.save_transcription.saved_and_next_notice') if next_page.id != @page.id
        @redirect_route = collection_sampling_review_page_path(
          @collection.owner,
          @collection, @quality_sampling,
          next_page.id, flow: 'quality-sampling'
        )
      else
        @redirect_route = collection_quality_sampling_path(@collection.owner, @collection, @quality_sampling)
      end
    else
      next_page_id = @page.last? || action_is_save? ? @page.id : @page.lower_item.id

      @notice = I18n.t('transcribe.save_transcription.saved_and_next_notice') if next_page_id != @page.id
      @redirect_route = transcribe_assign_categories_path(
        page_id: @page.id,
        collection_id: @collection,
        next_page_id: next_page_id,
        old_article_ids: @old_article_ids
      )
    end
  end
end
