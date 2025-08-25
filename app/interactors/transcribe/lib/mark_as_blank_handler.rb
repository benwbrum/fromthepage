class Transcribe::Lib::MarkAsBlankHandler < Transcribe::Lib::BaseHandler
  def initialize(page:, page_params:, user:)
    @page        = page
    @page_params = page_params
    @user        = user

    super()
  end

  def perform
    return @page if no_change_needed?

    if mark_as_blank?
      set_status(:blank)
      record_blank_deed
    else
      set_status(:new)
    end

    @page.save!
    @page.work.work_statistic.recalculate

    @page
  end

  private

  def mark_as_blank?
    ActiveModel::Type::Boolean.new.cast(@page_params[:mark_blank])
  end

  def no_change_needed?
    status_condition = (mark_as_blank? && @page.status_blank?) || (!mark_as_blank? && !@page.status_blank?)
    translation_status_condition = (mark_as_blank? && @page.translation_status_blank?) ||
      (!mark_as_blank? && !@page.translation_status_blank?)

    status_condition || translation_status_condition
  end

  def set_status(status)
    @page.status = status
    @page.translation_status = status
  end

  def record_blank_deed
    record_deed({
      page_id: @page.id,
      work_id: @page.work_id,
      collection_id: @page.collection.id,
      user_id: @user.id,
      deed_type: DeedType::PAGE_MARKED_BLANK
    })
  end
end
