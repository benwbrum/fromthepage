class ArticleController < ApplicationController
  before_filter :authorized?, :except => [:graph, :list, :show]

  include AbstractXmlController

  DEFAULT_ARTICLES_PER_GRAPH = 40

  def authorized?
    unless user_signed_in?
      redirect_to dashboard_path
    end
  end

  def list
    # Differences from previous implementation:
    # 1. List of articles needs to be collection-specific
    # 2. List should be displayed within the category treeview
    # 3. Uncategorized articles should be listed below

    @uncategorized_articles = Article.joins('LEFT JOIN articles_categories ac ON id = ac.article_id').where(['ac.category_id IS NULL AND collection_id = ?', @collection.id]).all

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

  def combine_duplicate
    # @article contains "to" article
    from_article = Article.find(params[:from_article_id])
    combine_articles(from_article, @article)
    flash[:notice] = "All links now point to #{@article.title}."
    redirect_to :action => 'show', :article_id => @article.id
  end


  def graph
    @categories = []
    if params[:category_ids]
      @categories = Category.find(params[:category_ids])
      @article.graph_image = nil
    end

#    if @article.graph_image && !params[:force]
#      return
#    end
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
    count_per_rank = { 0 => 0}
    article_links.each do |l|
      link_count = l['link_count'].to_i
      link_total += link_count
      if link_count > link_max
        link_max = link_count
      end
      # initialize for this rank if necessary
      if count_per_rank[link_count]
        # set this rank
        count_per_rank[link_count] += 1
      else
        count_per_rank[link_count] = 1
      end
      #logger.debug("DEBUG: \tcount_per_rank[#{link_count}]=#{count_per_rank[link_count]}\n")
    end

    #logger.debug("DEBUG: count per rank=#{count_per_rank.inspect}\n")

    min_rank=0
    # now we know how many articles each link count has, as well as the size
    if params[:min_rank]
      # use the min rank from the params
      min_rank = params[:min_rank].to_i
    else
      # calculate whether we should reduce the rank
      num_articles = article_links.size
      while num_articles > DEFAULT_ARTICLES_PER_GRAPH && min_rank < link_max
        # remove the outer rank
        #logger.debug("DEBUG: \tinvestigating rank #{min_rank} for #{num_articles}\n")
        num_articles -= count_per_rank[min_rank] || 0 # hash is sparse
        min_rank += 1
        logger.debug("DEBUG: \tnum articles now #{num_articles}\n")
      end
    end

    dot_path = "#{Rails.root}/app/views/article/graph.dot"

    dot_source =
      render_to_string({:file => dot_path,
                        :locals => { :article_links => article_links,
                                     :link_total => link_total,
                                     :link_max => link_max,
                                     :min_rank => min_rank }} )

    dot_file = "#{Rails.root}/public/images/working/dot/#{@article.id}.dot"
    File.open(dot_file, "w") do |f|
      f.write(dot_source)
    end
    # TEMP HACK: copy something to the .map file and png
    dot_out = "#{Rails.root}/public/images/working/dot/#{@article.id}.png"
    # THIS IS ORIG
    # dot_out_map = "#{Rails.root}/public/images/working/dot/#{@article.id}.map"
    # THIS IS HACK
    dot_out_map = "#{Rails.root}/public/images/working/dot/#{@article.id}.dot"
    # system "#{NEATO} -Tcmapx -o#{dot_out_map} -Tpng #{dot_file} -o #{dot_out}"

    @map = File.read(dot_out_map)
    @article.graph_image = dot_out
    @min_rank = min_rank
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

  def combine_articles(from_article, to_article)
    # rename the article to something bizarre in case they have the same name
    old_from_title = from_article.title
    from_article.title = 'TO_BE_DELETED:'+old_from_title
    from_article.save!

    # walk through all pages referring to from_article
    # walk through all pages referring to this
    for link in from_article.page_article_links
      source_text = link.page.source_text
      link.page.rename_article_links(old_from_title, to_article.title)
      logger.debug("DEBUG: changed \n#{source_text} \nto \n#{link.page.source_text}\n")
    end
    # walk through all articles referring to this
    for link in from_article.target_article_links
      source_text = link.article.source_text
      link.article.rename_article_links(old_from_title, to_article.title)
      logger.debug("DEBUG: changed \n#{source_text} \nto \n#{link.article.source_text}\n")
    end

    for link in from_article.source_article_links
      link.destroy
    end
    # thankfully, rename_article_links is source-agnostic!

    # change links
    Deed.update_all("article_id='#{to_article.id}'",
                    "article_id = #{from_article.id}")

    # append old from_article text to to_article text
    if from_article.source_text
      if to_article.source_text
        to_article.source_text += from_article.source_text
      else
        to_article.source_text = from_article.source_text
      end
    end
    # write to the DB
    to_article.save!
    from_article.destroy
  end

end
