class Api::PublicationController < Api::ApiController

   before_action :set_publication, only: [:show, :update, :destroy]


 def create
    @foro = Foro.find(params[:foro][:id])
    @publicacion = Publication.new
    @parent = nil
    if !params[:parent].nil?
      @parent = Publication.find(params[:parent][:id])
    end


    if !@parent.nil?
      @publicacion = @parent.children.create()

    end

    @publicacion.foro=@foro
    @publicacion.user=current_user
    @publicacion.text=params[:text]
    if  @publicacion.save
      params[:fields]="user"
      puts ResponseWS.ok("api.publication.create.success", @publicacion).data
      render_serialized ResponseWS.ok("api.publication.create.success", @publicacion)
    else
      render_serialized ResponseWS.default_error
    end
  end


  def update
    @publicacion.update_attributes(publication_params)
    render_serialized ResponseWS.ok("api.publication.update.success", @publicacion)
  end

  def destroy
    @publicacion.destroy
    render_serialized ResponseWS.ok("api.publication.destroy.success", @publicacion)
  end

  def show
     response_serialized_object @publicacion
  end


  def list
    @publications = Publication.where("parent_id IS NULL AND foro_id = ? ",params[:id])
    @list = Array.new()
    @publications.each do |publication|
      publication.assign_vote(current_user.voted_for? publication)
      @list.push(publication.getDTO)
    end
    response_serialized_object @list
  end

  def listByPublication
      @publications = Publication.where("parent_id = ? ",params[:publication_id])
      @list = Array.new()
      @publications.each do |publication|
        publication.assign_vote(current_user.voted_for? publication)
        @list.push(publication.getDTO)
      end
      render_serialized ResponseWS.ok("api.publication.list.success", @list)
  end

  def like
    @publication = Publication.find(params[:publication_id])
    @publication.liked_by current_user
    render_serialized ResponseWS.ok("api.publication.like", @publication)
  end

  def dislike
    puts "entro"
    @publication = Publication.find(params[:publication_id])
    @publication.unliked_by current_user
    render_serialized ResponseWS.ok("api.publication.dislike", @publication)
  end

    def publication_params
      params.permit(:foro,:text,:parent)
    end


    def set_publication
      @publicacion = Publication.find(params[:id])
      raise ActiveRecord::RecordNotFound unless @publicacion
    end



end
