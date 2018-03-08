require 'gamification_helper'

class BadgeController < ApplicationController


  def list
    @response = GamificationHelper.getPlayerInfoEvent(current_user.email)
    @badges = @response.player.badges
  end

end
