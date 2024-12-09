class ArticleController < ApplicationController
  include AbstractXmlController

  before_action :authorized?, except: [:list, :show, :tooltip, :graph]

  def tooltip
    render partial: 'tooltip'
  end

  def list
    articles = @collection.articles.includes(:categories)
    @categories = @collection.categories.includes(:articles)

    @vertical_articles = {}
    @categories.each do |category|
      current_articles = articles.where(categories: { id: category.id })
      @vertical_articles[category] = sort_vertically(current_articles)
    end

    @uncategorized_articles = sort_vertically(
      articles.where(categories: { id: nil }).reorder(:title)
    )
  end

  def delete
    result = Article::Destroy.call(
      article: @article,
      user: current_user,
      collection: @collection
    )

    if result.success?
      redirect_to collection_subjects_path(@collection.owner, @collection)
    else
      flash.alert = result.message
      redirect_to collection_article_show_path(@collection.owner, @collection, @article.id)
    end
  end

  def update
    if params[:save]
      result = Article::Update.call(
        article: @article,
        article_params: article_params
      )

      if result.success?
        record_deed

        flash[:notice] = result.notice
        redirect_to collection_article_edit_path(@collection.owner, @collection, @article)
      else
        @article = result.article
        render :edit, status: :unprocessable_entity
      end
    elsif params[:autolink]
      @article.source_text = autolink(@article.source_text)

      flash[:notice] = t('.subjects_auto_linking')
      render :edit
    else
      # Default to redirect
      redirect_to collection_article_edit_path(@collection.owner, @collection, @article)
    end
  end

  def article_category
    categories = Category.where(id: params[:category_ids])
    @article.categories = categories
    @article.save!

    respond_to(&:turbo_stream)
  end

  def combine_duplicate
    Article::Combine.call(
      article: @article,
      from_article_ids: params[:from_article_ids]
    )

    flash[:notice] = t('.selected_subjects_combined', title: @article.title)
    redirect_to collection_article_edit_path(@collection.owner, @collection, @article)
  end

  def graph
    redirect_to :action => :show, :article_id => @article.id
  end

  def show
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
    count_per_rank = { 0 => 0 }
    article_links.each do |l|
      link_count = l['link_count'].to_i
      link_total += link_count
      link_max = [link_count, link_max].max

      count_per_rank[link_count] ||= 0
      count_per_rank[link_count] += 1
    end

    min_rank = 0
    # now we know how many articles each link count has, as well as the size
    if params[:min_rank]
      # use the min rank from the params
      min_rank = params[:min_rank].to_i
    else
      # calculate whether we should reduce the rank
      num_articles = article_links.count
      while num_articles > DEFAULT_ARTICLES_PER_GRAPH && min_rank < link_max
        # remove the outer rank
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

  # actually process the uploaded CSV
  def subject_upload
    @collection = Collection.find params[:upload][:collection_id]
    # read the file
    file = params[:upload][:file].tempfile

    # csv = CSV.read(params[:upload][:file].tempfile, :headers => true)
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

  def record_deed
    deed = Deed.new
    deed.article = @article
    deed.deed_type = DeedType::ARTICLE_EDIT
    deed.collection = @article.collection
    deed.user = current_user
    deed.save!
    update_search_attempt_contributions
  end

  private

  def authorized?
    redirect_to dashboard_path unless user_signed_in?
  end

  def article_params
    params.require(:article).permit(:title, :uri, :source_text, :latitude, :longitude, category_ids: [])
  end

  def sort_vertically(articles)
    return [] unless articles.any?

    rows = (articles.length.to_f / LIST_NUM_COLUMNS).ceil
    vertical_articles = Array.new(rows) { Array.new(LIST_NUM_COLUMNS) }

    articles.each_with_index do |article, index|
      row = index % rows
      col = index / rows
      vertical_articles[row][col] = article
    end

    vertical_articles
  end

  def find_or_create_category(collection, title)
    category = collection.categories.where(title: title).first
    if category.nil?
      category = Category.new(title: title)
      collection.categories << category
    end

    category
  end
end
