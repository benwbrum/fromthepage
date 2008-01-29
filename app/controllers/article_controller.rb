class ArticleController < ApplicationController

  include AbstractXmlController

  def list
    @articles = Article.find(:all)
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
    if @article.graph_image
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
      " AND from_links.article_id != #{@article.id} "+
      "GROUP BY a.title, a.id "
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
    system "/usr/bin/neato -Tpng #{dot_file} -o #{dot_out}" 
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
  

end
