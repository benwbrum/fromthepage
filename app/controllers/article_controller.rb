class ArticleController < ApplicationController

  include AbstractXmlController

  def list
    # Differences from previous implementation:
    # 1. List of articles needs to be collection-specific
    # 2. List should be displayed within the category treeview
    # 3. Uncategorized articles should be listed below
    #@articles = Article.find(:all)
    
    @uncategorized_articles = 
      Article.find(:all, 
                   { :joins => 'LEFT JOIN articles_categories ac ON id = ac.article_id',
                     :conditions => ['ac.category_id IS NULL AND collection_id = ?',
                                     @collection.id]})
     
  end

  def update
    old_title = @article.title
    @article.attributes=params[:article]
    if params['save']
      #process_source_for_article
      if @article.save
        if old_title != @article.title
          rename_article(old_title, @article.title)
        end
        record_deed
        redirect_to :action => 'show', :article_id => @article.id
        return
      end
    elsif params['preview']
      @preview_xml = @article.generate_preview
    elsif params['autolink']
      @article.source_text = autolink(@article.source_text)
    end
    render :action => 'edit'
  end

  def article_category
    status = params[:status]
    if status == 'true'
      @article.categories << @category
    else
      @article.categories.delete(@category)
    end    
    render :text => "success"
  end 

  def graph
    @categories = []
    if params[:category_ids]
      @categories = Category.find(params[:category_ids])
      @article.graph_image = nil
    end
    if @article.graph_image && !params[:force]
      return
    end
    sql = 
      'SELECT count(*) as link_count, '+
      'a.title as title, '+
      'a.id as article_id '+
      'FROM page_article_links to_links '+
      'INNER JOIN page_article_links from_links '+
      '  ON to_links.page_id = from_links.page_id '+
      'INNER JOIN articles a '+
      '  ON from_links.article_id = a.id '+
      "WHERE to_links.article_id = #{@article.id} "+
      " AND from_links.article_id != #{@article.id} "
    if params[:category_ids]
      sql += " AND from_links.article_id IN "+
        "(SELECT article_id "+
        "FROM articles_categories "+
        "WHERE category_id IN (#{params[:category_ids].join(',')}))"
    end
    sql += "GROUP BY a.title, a.id "
    logger.debug(sql)
    article_links = Article.connection.select_all(sql)
    link_total = 0
    link_max = 0
    article_links.each do |l| 
      link_total += l['link_count'].to_i 
      if l['link_count'].to_i > link_max
        link_max = l['link_count'].to_i
      end
    end

    dot_path = "#{RAILS_ROOT}/app/views/article/graph.dot"

    dot_source = 
      render_to_string({:file => dot_path,
                        :locals => { :article_links => article_links,
                                     :link_total => link_total,
                                     :link_max => link_max  }} )

    dot_file = "#{RAILS_ROOT}/public/images/working/dot/#{@article.id}.dot"
    File.open(dot_file, "w") do |f|
      f.write(dot_source)
    end
    dot_out = "#{RAILS_ROOT}/public/images/working/dot/#{@article.id}.png"
    system "#{NEATO} -Tpng #{dot_file} -o #{dot_out}" 

    @article.graph_image = dot_out
    @article.save! 
  end

protected

  def rename_article(old_name, new_name)
    # walk through all pages referring to this
    for link in @article.page_article_links
      source_text = link.page.source_text
      link.page.rename_article_links(old_name, new_name)
      logger.debug("DEBUG: changed \n#{source_text} \nto \n#{link.page.source_text}\n")
    end
    # walk through all articles referring to this
    for link in @article.target_article_links
      source_text = link.article.source_text
      link.article.rename_article_links(old_name, new_name)
      logger.debug("DEBUG: changed \n#{source_text} \nto \n#{link.article.source_text}\n")
    end
  end

  def record_deed
    deed = Deed.new
    deed.article = @article
    deed.deed_type = Deed::ARTICLE_EDIT
    deed.collection = @article.collection
    deed.user = current_user
    deed.save!
  end
  

end
