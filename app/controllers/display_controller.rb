class DisplayController < ApplicationController
  public :render_to_string
  in_place_edit_for :note, :body
  
  protect_from_forgery :except => [:set_note_body]

  PAGES_PER_SCREEN = 5

  def read_work
    @work = Work.find_by_id(params[:url][:work_id])
    if @article
      logger.debug("in display controller, work.id is #{@work.id}, if @article is true")
      # restrict to pages that include that subject
      @pages = Page.paginate_by_work_id @work.id, :page => params[:page],  
                                        :order => 'position',
                                        :per_page => PAGES_PER_SCREEN,
                                        :joins => 'INNER JOIN page_article_links pal ON pages.id = pal.page_id',
                                        :conditions => [ 'pal.article_id = ?', @article.id ]
      @pages.uniq!
    else
#            @pages = Page.paginate @work.id, :page => params[:page]
            @pages = Page.paginate :page => params[:page],  
                                        :order => 'position',
                                        :per_page => PAGES_PER_SCREEN,
                                        :conditions => { :work_id => @work.id }
=begin
      @pages = Page.paginate_by_work_id @work.id, :page => params[:page],  
                                        :order => 'position',
                                        :per_page => PAGES_PER_SCREEN
=end
    end                                      
  end

  def read_all_works
    if @article
      # restrict to pages that include that subject
      @pages = Page.paginate :all, :page => params[:page],  
                                        :order => 'work_id, position',
                                        :per_page => 5,
                                        :joins => 'INNER JOIN page_article_links pal ON pages.id = pal.page_id',
                                        :conditions => [ 'pal.article_id = ?', @article.id ]
      @pages.uniq!
    else
      @pages = Page.paginate :all, :page => params[:page],  
                                        :order => 'work_id, position',
                                        :per_page => 5
    end                                      
  end

  def search
    if @article
      # get the unique search terms
      terms = []
      @search_string = ""
      @article.page_article_links.each do |link|
        terms << link.display_text.gsub(/\s+/, ' ')
      end
      terms.uniq!
      # process them for display and search
      terms.each do |term|
        # don't add required text
        if term.match(/ /)
          @search_string += "\"#{term}\" "
        else
          @search_string += term + "* "
        end
      end
      if params[:unlinked_only]
        conditions = 
          ["works.collection_id = ? "+
          "AND MATCH(xml_text) AGAINST(? IN BOOLEAN MODE)"+
          " AND pages.id not in "+
          "    (SELECT page_id FROM page_article_links WHERE article_id = ?)",
          @collection.id,
          @search_string,
          @article.id]

      else
        conditions = 
          ["works.collection_id = ? "+
          "AND MATCH(xml_text) AGAINST(? IN BOOLEAN MODE)", 
          @collection.id,
          @search_string]
      end
      @pages = Page.paginate :all, :page => params[:page],  
                                        :order => 'work_id, position',
                                        :per_page => 5,
                                        :joins => :work,
                                        :conditions => conditions
    else  
      @search_string = params[:search_string]
      # convert 'natural' search strings unless they're precise
      unless @search_string.match(/["+-]/)
        @search_string.gsub!(/(\S+)/, '+\1*')
      end
      # restrict to pages that include that subject
      @pages = Page.paginate :all, :page => params[:page],  
                                        :order => 'work_id, position',
                                        :per_page => 5,
                                        :joins => :work,
                                        :conditions =>
                                          ["works.collection_id = ? AND MATCH(xml_text) AGAINST(? IN BOOLEAN MODE)", 
                                          @collection.id,
                                          @search_string]
    end                                      
    logger.debug "DEBUG #{@search_string}"
  end

  def too_small
    # change the page-to-base halvings
    session[:myopic] = 1
    redirect_to :controller => params[:origin_controller], :action => params[:origin_action], :page_id => @page.id
  end

  def too_big
    session[:myopic] = nil   
    redirect_to :controller => params[:origin_controller], :action => params[:origin_action], :page_id => @page.id
  end

end
