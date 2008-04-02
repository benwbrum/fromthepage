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
    else
      @pages = Page.paginate_by_work_id @work.id, :page => params[:page],  
                                        :order => 'position',
                                        :per_page => 5
    end                                      
                                      

#    articles = []
#    @pages.each { |page| articles += page.articles }
#    articles.uniq!
#    @categories = []
#    logger.debug("DEBUG #{articles.inspect}")
#    articles.each { |article| @categories += article.categories }
#    logger.debug(@categories.length)
#    @categories.uniq!
#    # TODO -- figure out how to display parent categories for children without expanding them!
#    # note: to make this work, we need to walk through each article,
#    # walk through its's categories and add each parent category to the list
#    # then pass that list to the treeview control as a "don't show anything but these"
#    # contstraint.
#    # 
#    # I will not, however do that since it seems more important for the
#    # Category treeview to be consistent between views than to restrict it.
#    logger.debug(@categories.length)
  end
end
