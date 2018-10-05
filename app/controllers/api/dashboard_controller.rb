class Api::DashboardController < Api::ApiController

  include AddWorkHelper

  before_filter :authorized?, :only => [:owner, :staging, :omeka, :startproject]
  before_filter :get_data, :only => [:owner, :staging, :omeka, :upload, :new_upload, :startproject, :empty_work, :create_work]





  def get_data
      puts "recent works"
    @collections = current_user.all_owner_collections
    @notes = current_user.notes
    @works = current_user.owner_works
    @ia_works = current_user.ia_works
    @document_sets = current_user.document_sets
    logger.debug("DEBUG: #{current_user.inspect}")
    response_serialized_object (@works)
  end

  #Public Dashboard - list of all collections
  def index
    @deeds = Array.new
    collections = Collection.includes(:owner, :works).joins(:deeds).where(deeds: {created_at: (1.year.ago..Time.now)}).distinct
    @document_sets = DocumentSet.includes(:owner, :works).joins(works: :deeds).where(deeds: {created_at: (1.year.ago..Time.now)}).distinct
    @collections = (collections + @document_sets).sort{|a,b| a.title <=> b.title }
    @collections.each do |c|
    @dashboard_data = CollectionDashboard.new(c)
      c.deeds.includes(:user, :page, :work).limit(5).each do |d|
        deedDTO = DeedDTO.new(d)
        @deeds.push deedDTO
      end

    end

    response_serialized_object (@deeds)
  end

  #Owner Dashboard - start project
  #other methods in AddWorkHelper
  def startproject
    @work = Work.new
    @work.collection = @collection
    @document_upload = DocumentUpload.new
    @document_upload.collection=@collection
    @omeka_items = OmekaItem.all
    @omeka_sites = current_user.omeka_sites
    @sc_collections = ScCollection.all
  end

  #Owner Dashboard - list of works
  def owner
  end


  #Collaborator Dashboard - watchlist
  def watchlist
    works = Work.joins(:deeds).where(deeds: {user_id: current_user.id}).distinct
    collections = Collection.joins(:deeds).where(deeds: {user_id: current_user.id}).distinct.order_by_recent_activity.limit(5)
    document_sets = DocumentSet.joins(works: :deeds).where(works: {id: works.ids}).order('deeds.created_at DESC').distinct.limit(5)
    @collections = (collections + document_sets).sort{|a,b| a.title <=> b.title }.take(5)
    @page = recent_work
  end

  #Collaborator Dashboard - user with no activity watchlist
  def recent_work
     puts "recent works"
    recent_deed_ids = Deed.joins(:collection, :work).merge(Collection.unrestricted).merge(Work.unrestricted)
                  .where("work_id is not null").order('created_at desc').distinct.limit(5).pluck(:work_id)
    @works = Work.joins(:pages).where(id: recent_deed_ids).where(pages: {status: nil})

#find the first blank page in the most recently accessed work (as long as the works list isn't blank)
    unless @works.empty?
      recent_work = @works.first.pages.where(status: nil).first
    #if the works list is blank, return nil
    else
      recent_work = nil
    end
    response_serialized_object @rece
  end


  #Collaborator Dashboard - activity
  def editor
    @user = current_user
  end

  #Guest Dashboard - activity
  def guest
    @deeds = Array.new
    @hash = Array.new
    @collections = Collection.order_by_recent_activity.unrestricted.distinct.limit(5)
    @collections.group_by{|x| x.title}.values
    @collections.each do |c|
    @dashboard_data = CollectionDashboard.new(c)
      c.deeds.includes(:user, :page, :work).limit(5).each do |d|
        deedDTO = DeedDTO.new(d)
        @deeds.push deedDTO
      end
      @response=DashboardResponse.new
      @response.collection=c.title
      @response.description=c.intro_block
      @response.deeds=@deeds
      @hash.push @response
      @deeds=Array.new
    end

    response_serialized_object @hash
  end




  def ownerResponse
    @deeds = Array.new

    @collections = current_user.all_owner_collections.includes(:works)
    @collections.each do |c|
        c.deeds.includes(:user, :page, :work).limit(5).each do |d|
        deedDTO = DeedDTO.new(d)
        @deeds.push deedDTO
      end
    end

      #@hash.push @response
      #@deeds=Array.new
    response_serialized_object @deeds.sort! { |a, b|  a.created_at <=> b.created_at }.reverse
  end

  def collectionsOfOwner
    puts "collection owner"
    @deeds = Array.new
    @hash = Hash.new
    @notesSize=0
    @worksSize=0
    @collections = current_user.all_owner_collections.includes(:works)
    @collections.each do |c|
      @collectionDto = CollectionDTO.new(c,c.works,c.notes)
      @deeds.push @collectionDto
      @notesSize=@notesSize+c.notes.count
      @worksSize=@worksSize+c.works.count
    end
    @hash['collections']=@deeds
    @hash['works'] = @worksSize
    @hash['notes'] = @notesSize
    @hash['collectionSize'] = @collections.count
    response_serialized_object @hash
  end

  def workActivity
    puts "work Activity"
    @deedsDto =Array.new
    @deeds = current_user.all_owner_deeds_work(params[:work_id])
    @deeds.each do |d|
      deedDTO = d.getDTO()
      @deedsDto.push deedDTO
    end
    response_serialized_object @deedsDto
  end


end
