# frozen_string_literal: true

ActiveSupport.on_load :turbo_streams_tag_builder do
  def redirect(url, response: nil)
    turbo_stream_action_tag :redirect, url: url, response: response
  end
end
