# handles logging for client-side errors
class LogController < ApplicationController
  def log
    debug(session.session_id)
    debug(request.env['HTTP_USER_AGENT'])
    debug(request.env['REMOTE_ADDR'])
    #debug(params[:message])
    params[:message].split('_').each { |message| debug(message) }
    render :text => ''
  end

  def debug(message)
    logger.debug("CLIENT DEBUG: #{message}")
  end
end
