class Api::DeedController < Api::ApiController

  PAGES_PER_SCREEN = 50

  def list
    condition = []
    @collection_id = params[:id]
    if @collection_id
      puts "llego coleccion"
      condition = ['collection_id = ?', @collection_id]
    elsif @user
      puts "llego usuario"
      condition = ['user_id = ?', @user.id]
    elsif @collection_ids
      puts "todo"
      @deeds = Deed.where(collection_id: @collection_ids).order('created_at DESC').paginate :page => params[:page], :per_page => PAGES_PER_SCREEN
      return
    end
    @deeds = Deed.where(condition).order('created_at DESC').paginate :page => params[:page], :per_page => PAGES_PER_SCREEN
    @deeds = Deed.joins(:work)
    
    d = @deeds.first

    @devo = DeedDTO.new(d)
    response_serialized_object (@devo)
  end

end
