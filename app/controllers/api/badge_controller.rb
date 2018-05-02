require 'gamification_helper'

class Api::BadgeController < Api::ApiController

  def list
    @response = GamificationHelper.getPlayerInfoEvent(current_user.email)
    response_serialized_object @response.player.badges
  end

end
