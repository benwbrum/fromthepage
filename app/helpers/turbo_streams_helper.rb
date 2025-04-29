module TurboStreamsHelper
  def turbo_flash(message, type)
    turbo_stream.append('flash_wrapper', partial: '/shared/flash', locals: { type: type, message: message })
  end
end
