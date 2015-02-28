class DashboardController < ApplicationController

  def index
    logger.debug("DEBUG: #{current_user.inspect}")
    if user_signed_in?
      @image_sets = current_user.image_sets
    end
    @collections = Collection.all
    @users = User.all

    @offset = params[:offset] || 0
    @recent_versions = PageVersion.where('page_versions.created_on desc').limit(20).offset(@offset).includes([:user, :page]).all

    sql =
      'SELECT count(DISTINCT user_id) count '+
      'FROM interactions '+
      'WHERE created_on > date_sub("'+ Time.now.utc.to_s() +'", INTERVAL 20 MINUTE) '+
      'AND user_id IS NOT NULL'

    @user_count = Interaction.connection.select_value(sql)
  end

end

