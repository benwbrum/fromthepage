class ArticleController < ApplicationController
  before_action :authorized?, :except => [:list, :show, :tooltip, :graph]


  include AbstractXmlController

  DEFAULT_ARTICLES_PER_GRAPH = 40
  GIS_DECIMAL_PRECISION = 5
  LIST_NUM_COLUMNS = 3

  def authorized?
    unless user_signed_in?
      redirect_to dashboard_path
    end
  end

  def tooltip
    render partial: 'tooltip'
  end

  def list
    @categories = @collection.categories
    # Differences from previous implementation:
    # 1. List of articles needs to be collection-specific
    # 2. List should be displayed within the category treeview
    # 3. Uncategorized articles should be listed below
    if @collection.is_a?(DocumentSet)
      @uncategorized_articles = @collection.articles.joins('LEFT JOIN articles_categories ac ON articles.id = ac.article_id').where('ac.category_id IS NULL').reorder(:title)
    else
      @uncategorized_articles = @collection.articles.where.not(:id => @collection.articles.joins(:categories).pluck(:id)).reorder(:title)
    end

    # Create a 2D array of articles/subjects for each category
    # where the articles are sorted alphabetically vertically
    # instead of horizontally -- so, going down each column
    @vertical_articles = {} # Holds articles for each category
    @categories.each do |category|
      articles = category.articles_list(@collection) # The articles for this category
      @vertical_articles[category] = sort_vertically(articles)
    end

    # Do the same for uncategorized articles
    if @uncategorized_articles.present?
      @uncategorized_articles = sort_vertically(@uncategorized_articles)
    end
  end

  def delete
    if @article.link_list.empty? && @article.target_article_links.empty?
      if @article.created_by == current_user || current_user.like_owner?(@collection)
        @article.destroy 
        redirect_to collection_subjects_path(@collection.owner, @collection)
      else
        flash.alert = t('.only_subject_owner_can_delete')
        redirect_to collection_article_show_path(@collection.owner, @collection, @article.id)
      end
    else
      flash.alert = t('.must_remove_referring_links')
      redirect_to collection_article_show_path(@collection.owner, @collection, @article.id)
    end
  end

  def update
    old_title = @article.title
    gis_truncated = gis_truncated?(params[:article], GIS_DECIMAL_PRECISION)

    @article.attributes = article_params
    if params['save']
      #process_source_for_article
      if @article.save
        if old_title != @article.title
          rename_article(old_title, @article.title)
        end
        record_deed
        flash[:notice] = t('.subject_successfully_updated')
        if gis_truncated 
          flash[:notice] << t('.gis_coordinates_truncated', precision: GIS_DECIMAL_PRECISION, count: GIS_DECIMAL_PRECISION)
        end
        redirect_to :action => 'edit', :article_id => @article.id
      else
        render :action => 'edit'
      end
    elsif params['autolink']
      @article.source_text = autolink(@article.source_text)
      flash[:notice] = t('.subjects_auto_linking')
      redirect_to :action => 'edit', :article_id => @article.id
    end
  end

  def article_category
    status = params[:status]
    if status == 'true'
      @article.categories << @category
    else
      @article.categories.delete(@category)
    end
    render :plain => "success"
  end

  def combine_duplicate
    #@article contains "to" article
    params[:from_article_ids].each do |from_article_id|
      from_article = Article.find(from_article_id)
      combine_articles(from_article, @article)
    end

    flash[:notice] = t('.selected_subjects_combined', title: @article.title)
    redirect_to collection_article_edit_path(@collection.owner, @collection, @article)
  end

  def graph
    redirect_to :action => :show, :article_id => @article.id
  end

  def show
    #if @article.graph_image && !params[:force]
    #   return
    #end
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
      num_articles = article_links.count
      while num_articles > DEFAULT_ARTICLES_PER_GRAPH && min_rank < link_max
        # remove the outer rank
        #logger.debug("DEBUG: \tinvestigating rank #{min_rank} for #{num_articles}\n")
        num_articles -= count_per_rank[min_rank] || 0 # hash is sparse
        min_rank += 1
        logger.debug("DEBUG: \tnum articles now #{num_articles}\n")
      end
    end

    dot_source =
      render_to_string(:partial => "graph.dot",
                       :layout => false,
                       :locals => { :article_links => article_links,
                                    :link_total => link_total,
                                    :link_max => link_max,
                                    :min_rank => min_rank })

    dot_file = "#{Rails.root}/public/images/working/dot/#{@article.id}.dot"
    File.open(dot_file, "w") do |f|
      f.write(dot_source)
    end
    dot_out = "#{Rails.root}/public/images/working/dot/#{@article.id}.png"
    dot_out_map = "#{Rails.root}/public/images/working/dot/#{@article.id}.map"

    system "#{Rails.application.config.neato} -Tcmapx -o#{dot_out_map} -Tpng #{dot_file} -o #{dot_out}"

    @map = File.read(dot_out_map)
    @article.graph_image = dot_out
    @article.save!
    session[:col_id] = @collection.slug
  end


  # display the article upload form
  def upload_form
  end


  def find_or_create_category(collection, title)
    category = collection.categories.where(:title => title).first
    if category.nil?
      category = Category.new(:title => title)
      collection.categories << category
    end

    category
  end

  # actually process the uploaded CSV
  def subject_upload
    @collection = Collection.find params[:upload][:collection_id]
    # read the file
    file = params[:upload][:file].tempfile

#    csv = CSV.read(params[:upload][:file].tempfile, :headers => true)
    begin
      csv = CSV.read(params[:upload][:file].tempfile, :headers=>true)
    rescue
      contents = File.read(params[:upload][:file].tempfile)
      detection = CharlockHolmes::EncodingDetector.detect(contents)

      csv = CSV.read(params[:upload][:file].tempfile, 
                      :encoding => "bom|#{detection[:encoding]}",
                      :liberal_parsing => true,
                      :headers => true)
    end


    provenance = params[:upload][:file].original_filename + " (uploaded #{Time.now} UTC)"
    # check the values
    if csv.headers.include?('HEADING') && csv.headers.include?('URI') && csv.headers.include?('ARTICLE') && csv.headers.include?('CATEGORY')
      # create subjects if heading checks out
      csv.each do |row|
        title = row['HEADING']
        article = @collection.articles.where(:title => title).first || Article.new(:title => title, :provenance => provenance)
        article.collection = @collection
        article.source_text = row['ARTICLE']
        article.uri = row['URI']
        article.categories << find_or_create_category(@collection, row['CATEGORY'])
        article.save!
      end
      # redirect to subject list
      redirect_to collection_subjects_path(@collection.owner, @collection)
    else      
      # flash message and redirect to upload form on problems
      flash[:error] = t('.csv_file_must_contain_headers')
      redirect_to article_upload_form_path(@collection)    
    end
  end


  def upload_example
    example = File.read(File.join(Rails.root, 'app', 'views', 'static', 'subject_example.csv'))
    send_data example, filename: "subject_example.csv"
  end

  protected

  def rename_article(old_name, new_name)
    # walk through all pages referring to this
    for link in @article.page_article_links
      source_text = link.page.source_text
      link.page.rename_article_links(old_name, new_name)
      link.page.save!
      logger.debug("DEBUG: changed \n#{source_text} \nto \n#{link.page.source_text}\n")
    end
    # walk through all articles referring to this
    for link in @article.target_article_links
      source_text = link.article.source_text
      link.article.rename_article_links(old_name, new_name)
      link.article.save!
      logger.debug("DEBUG: changed \n#{source_text} \nto \n#{link.article.source_text}\n")
    end
  end

  def record_deed
    deed = Deed.new
    deed.article = @article
    deed.deed_type = DeedType::ARTICLE_EDIT
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
      link.page.save!
      logger.debug("DEBUG: changed \n#{source_text} \nto \n#{link.page.source_text}\n")
    end
    # walk through all articles referring to this
    for link in from_article.target_article_links
      source_text = link.source_article.source_text
      link.source_article.rename_article_links(old_from_title, to_article.title)
      link.source_article.save!
      logger.debug("DEBUG: changed \n#{source_text} \nto \n#{link.source_article.source_text}\n")
    end

    for link in from_article.source_article_links
      link.destroy
    end
    # thankfully, rename_article_links is source-agnostic!

    # change links
    Deed.where(:article_id => from_article.id).update_all("article_id='#{to_article.id}'")

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

  def gis_truncated?(params, dec)
    unless params[:latitude] || params[:longitude] then return false end

    lat = params[:latitude].split('.')
    lon = params[:longitude].split('.')

    if lat.length == 2 then lat_dec = lat.last.length else lat_dec = 0 end
    if lon.length == 2 then lon_dec = lon.last.length else lon_dec = 0 end

    if lat_dec > dec || lon_dec > dec then return true else return false end
  end

  def sort_vertically(articles)
    rows = (articles.length().to_f / LIST_NUM_COLUMNS).ceil
    vertical_articles = Array.new(rows) { Array.new(LIST_NUM_COLUMNS) } # 2D array of articles

    row = 0
    col = 0
    articles.each do |article|
      vertical_articles[row][col] = article
      row+=1          # Go down a row each time
      if row == rows  # When you reach the bottom, move to the next column
        col+= 1
        row = 0
      end
    end

    return vertical_articles
  end

  private

  def article_params
    params.require(:article).permit(:title, :uri, :source_text, :latitude, :longitude)
  end
end
