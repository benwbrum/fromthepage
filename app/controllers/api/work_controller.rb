# handles administrative tasks for the work object
class Api::WorkController < Api::ApiController
  # require 'ftools'
  # include XmlSourceProcessor

  # protect_from_forgery :except => [:set_work_title,
  #                                  :set_work_description,
  #                                  :set_work_physical_description,
  #                                  :set_work_document_history,
  #                                  :set_work_permission_description,
  #                                  :set_work_location_of_composition,
  #                                  :set_work_author,
  #                                  :set_work_transcription_conventions]
  # tested
  #before_filter :authorized?, :only => [:edit, :pages_tab, :delete, :new, :create]
  before_action :set_work, :only => [:show, :edit, :update, :destroy]

  # no layout if xhr request
  # layout Proc.new { |controller| controller.request.xhr? ? false : nil }, :only => [:new, :create]

  def public_actions
    return [:show,:show_pages]
  end

  def destroy
    @work.destroy
    # redirect_to dashboard_owner_path
    render_serialized ResponseWS.ok('api.work.destroy.success',@work)
  end

  def show    
    response_serialized_object @work
  end

  # Probably we need this
  #
  # def versions
  #   @page_versions = PageVersion.joins(:page).where(['pages.work_id = ?', @work.id]).order('page_versions.created_on DESC').paginate(page: params[:page], per_page: 20)
  # end
  #
  # def add_scribe
  #   @work.scribes << @user
  #   redirect_to :action => 'edit', :work_id => @work
  # end
  # 
  # def remove_scribe
  #   @work.scribes.delete(@user)
  #   redirect_to :action => 'edit', :work_id => @work
  # end

  # tested
  def create
    @work = Work.new
    @work.title = params[:work][:title]
    @work.collection_id = params[:work][:collection_id]
    @work.description = params[:work][:description]
    @work.owner = current_user
    @collections = current_user.all_owner_collections

    if @work.save
      # record activity on gamification services 
      alert = GamificationHelper.createWorkEvent(current_user.email)
      
      record_deed(@work)
      # flash[:notice] = 'Work created successfully'
      # ajax_redirect_to({ :controller => 'work', :action => 'pages_tab', :work_id => @work.id, :anchor => 'create-page' })

      render_serialized ResponseWS.ok('api.work.create.success',@work,alert)
    else
      render_serialized ResponseWS.default_error
    end
  end

  def update
    work = @work
    id = work.collection_id
    #check the work transcription convention against the collection version
    #if they're the same, don't update that attribute of the work
    params_convention = params[:work][:transcription_conventions]
    collection_convention = work.collection.transcription_conventions

    if params_convention == collection_convention
      work.update_attributes(params[:work].except(:transcription_conventions))
    else
      work.update_attributes(params[:work])
    end

    #if the slug field param is blank, set slug to original candidate
    if params[:work][:slug] == ""
      title = work.title.parameterize
      work.update(slug: title)
    end

    if params[:work][:collection_id] != id.to_s
      change_collection
      # flash[:notice] = 'Work updated successfully'
      #find new collection to properly redirect
      # col = Collection.find_by(id: work.collection_id)
      # redirect_to edit_collection_work_path(col.owner, col, work)
    else
      # flash[:notice] = 'Work updated successfully'
      # redirect_to :back
    end
    
    render_serialized ResponseWS.ok('api.work.update.success',work)
  end

  def change_collection
    work = Work.find_by(id: params[:id])

    record_deed(work)
    unless work.articles.blank?
      #delete page_article_links for this work
      page_ids = work.pages.ids
      links = PageArticleLink.where(page_id: page_ids)
      links.destroy_all

      #remove links from pages in this work
      work.pages.each do |p|
        unless p.source_text.nil?
          p.remove_transcription_links(p.source_text)
        end
        unless p.source_translation.nil?
          p.remove_translation_links(p.source_translation)
        end
      end
      work.save!
    end
  end
  
  def show_pages
    @pages = @work.pages
    response_serialized_object @pages
  end

  # def revert
  #   work = Work.find_by(id: params[:work_id])
  #   work.update_attribute(:transcription_conventions, nil)
  #   render :text => work.collection.transcription_conventions
  # end

  # def update_featured_page
  #   @work.update(featured_page: params[:page_id])
  #   redirect_to :back
  # end

  protected
  def record_deed(work)
    deed = Deed.new
    deed.work = work
    deed.deed_type = Deed::WORK_ADDED
    deed.collection = work.collection
    deed.user = work.owner
    deed.save!
  end

  private
    def set_work
      unless @work
        if Work.friendly.exists?(params[:id])
          @work = Work.friendly.find(params[:id])
        elsif !Work.find_by(slug: params[:id]).nil?
          @work = Work.find_by(slug: params[:id])
        end
      end
    end

end
