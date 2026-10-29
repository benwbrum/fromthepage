class Article::GenerateGraph < ApplicationInteractor
  attr_accessor :article

  LOCK_TIMEOUT = 15
  DEFAULT_ARTICLES_PER_GRAPH = 40

  def initialize(article:, min_rank: 0)
    @article = article
    @min_rank = min_rank.to_i

    super
  end

  def perform
    return if @article.graph_attachment.attached?

    Article.with_advisory_lock(lock_key, timeout_seconds: LOCK_TIMEOUT) do
      # NOTE: Need this second check due to race conditions
      # before and after the lock
      return if @article.graph_attachment.attached?

      generate_and_attach_graph
    end
  end

  private

  def lock_key
    @lock_key ||= "article-#{@article.id}-attachment"
  end

  def generate_and_attach_graph
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
    sql += 'GROUP BY a.title, a.id '

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

    num_articles = article_links.count
    while num_articles > DEFAULT_ARTICLES_PER_GRAPH && @min_rank < link_max
      num_articles -= count_per_rank[@min_rank] || 0
      @min_rank += 1
    end

    dot_source = ApplicationController.render(
      partial: 'article/graph',
      layout: false,
      locals: {
        article: @article,
        article_links: article_links,
        link_total: link_total,
        link_max: link_max,
        min_rank: @min_rank
      },
      formats: [:dot]
    )

    dot_file    = Tempfile.new(["#{@article.id}-", '.dot'])
    dot_out     = Tempfile.new(["#{@article.id}-", '.png'])
    dot_out_map = Tempfile.new(["#{@article.id}-", '.map'])

    begin
      dot_file.write(dot_source)
      dot_file.close
      dot_out.close
      dot_out_map.close

      system "#{Rails.application.config.neato} -Tcmapx -o#{dot_out_map.path} -Tpng #{dot_file.path} -o #{dot_out.path}"

      File.open(dot_out.path, 'rb') do |f|
        @article.graph_attachment.attach(
          io: f,
          filename: "#{@article.id}.png",
          content_type: 'image/png'
        )
      end

      File.open(dot_out_map.path, 'r') do |f|
        @article.map_attachment.attach(
          io: f,
          filename: "#{@article.id}.map",
          content_type: 'text/html'
        )
      end
    ensure
      dot_file.unlink
      dot_out.unlink
      dot_out_map.unlink
    end

    discard_unsaved_graph_attachments
  end

  # ActiveStorage#attach on a persisted record saves it; when that save fails
  # (e.g. the article no longer passes validation) the attachments stay in
  # memory with unsaved blobs and the view blows up with
  # "Cannot get a signed_id for a new record". Drop them so the page still renders.
  def discard_unsaved_graph_attachments
    return if @article.graph_attachment.blob&.persisted? && @article.map_attachment.blob&.persisted?

    @article.reload
  end
end
