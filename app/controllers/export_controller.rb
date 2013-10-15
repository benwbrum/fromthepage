class ExportController < ApplicationController
  
  def show
    render :layout => false
  end

  def tei
    params[:format] = 'xml'# if params[:format].blank?
    
    @user_contributions = 
      User.find_by_sql("SELECT  user_id user_id, 
                                users.print_name print_name, 
                                count(*) edit_count, 
                                min(page_versions.created_on) first_edit, 
                                max(page_versions.created_on) last_edit 
                        FROM    page_versions 
                        INNER JOIN pages 
                            ON page_versions.page_id = pages.id 
                        INNER JOIN users 
                            ON page_versions.user_id = users.id 
                        WHERE pages.work_id = #{@work.id} 
                          AND page_versions.transcription IS NOT NULL 
                        GROUP BY user_id 
                        ORDER BY count(*) DESC")

    @work_versions = PageVersion.find(:all, :joins => :page,
                        :conditions => ['pages.work_id = ?', @work.id],
                       :order => "work_version")

    @all_articles = @work.articles
    @person_articles = []
    @place_articles = []
    @other_articles = []
    
    @all_articles.each do |article|
      # TODO replace this with legitimate flow control once I get to a ruby lang doc
      other = true 
      if article.categories.where(:title => 'Places').count > 0
        @place_articles << article
        other = false
      end
      if article.categories.where(:title => 'People').count > 0
        @person_articles << article
        other = false
      end
      @other_articles << article if other                  
    end
    render :layout => false, :content_type => "application/xml"
  end





end
