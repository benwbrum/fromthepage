class Admin::Ai::ErrorsController < Admin::Ai::BaseController
  DEFAULT_PER_PAGE = 50

  def index
    @ai_transcriptions = AiTranscription
      .where(status: :error)
      .includes(page: { work: :collection })
      .order(updated_at: :desc)
      .paginate(page: params[:page], per_page: DEFAULT_PER_PAGE)

    @current_section = :errors
  end

  def show
    @ai_transcription = AiTranscription.where(status: :error).find(params[:id])
    @page = @ai_transcription.page
    @work = @page.work
    @collection = @work.collection

    @current_section = :errors
  end
end
