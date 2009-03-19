class DisplayController < ApplicationController
  public :render_to_string

  def read_work
    if @article
      # restrict to pages that include that subject
      @pages = Page.paginate_by_work_id @work.id, :page => params[:page],  
                                        :order => 'position',
                                        :per_page => 5,
                                        :joins => 'INNER JOIN page_article_links pal ON pages.id = pal.page_id',
                                        :conditions => [ 'pal.article_id = ?', @article.id ]
      @pages.uniq!
    else
      @pages = Page.paginate_by_work_id @work.id, :page => params[:page],  
                                        :order => 'position',
                                        :per_page => 5
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

end
