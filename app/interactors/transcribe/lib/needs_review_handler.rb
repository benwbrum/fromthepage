class Transcribe::Lib::NeedsReviewHandler < Transcribe::Lib::BaseHandler
  def initialize(page:, page_params:, user:, type: :transcription, save_to_needs_review: false)
    @page                 = page
    @page_params          = page_params
    @user                 = user
    @type                 = type
    @save_to_needs_review = save_to_needs_review

    super()
  end

  def perform
    if @type == :translation
      handle_translation
    else
      handle_transcription
    end

    @page
  end

  private

  def needs_review?
    @needs_review ||= ActiveModel::Type::Boolean.new.cast(@page_params[:needs_review])
  end

  def review_workflow?
    @review_workflow ||= @page.collection.review_workflow
  end

  def handle_translation
    if review_workflow? && @page.translation_status_new?
      # Review Workflow and status is new
      @page.translation_status = :needs_review
      record_review_deed(DeedType::TRANSLATION_REVIEW)
    elsif needs_review? && !@page.translation_status_needs_review?
      # Needs review checked and status is not needs review
      @page.translation_status = :needs_review
      record_review_deed(DeedType::TRANSLATION_REVIEW)
    elsif !needs_review? && @page.translation_status_needs_review?
      # Needs review unchecked and status is needs review
      @page.translation_status = :new
      record_review_deed(DeedType::TRANSLATION_REVIEWED)
    end
  end

  def handle_transcription
    if @save_to_needs_review && review_workflow?
      # Clicked save to needs review and Review Workflow
      unless @page.status_needs_review?
        @page.status = :needs_review
        record_review_deed(DeedType::NEEDS_REVIEW)
      end
    elsif needs_review? && !@page.status_needs_review?
      # Needs review checked and status is not needs review
      @page.status = :needs_review
      record_review_deed(DeedType::NEEDS_REVIEW)
    elsif !needs_review? && @page.status_needs_review?
      # Needs review unchecked and status is needs review
      @page.status = :new
      record_review_deed(DeedType::PAGE_REVIEWED)
    end
  end

  def record_review_deed(deed_type)
    record_deed({
      page_id: @page.id,
      work_id: @page.work_id,
      collection_id: @page.collection.id,
      user_id: @user.id,
      deed_type: deed_type
    })
  end
end
