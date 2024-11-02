class Article::Update
  include Interactor
  include Article::Lib::Common

  def initialize(article:, article_params:)
    @article        = article
    @article_params = article_params

    super
  end

  def call
    old_title = @article.title
    @article.attributes = @article_params

    if @article.save
      rename_article(@article, old_title, @article.title) if old_title != @article.title

      notice = I18n.t('article.update.subject_successfully_updated')
      if gis_truncated?
        notice << I18n.t('article.update.gis_coordinates_truncated', precision: GIS_DECIMAL_PRECISION,
                                                                     count: GIS_DECIMAL_PRECISION)
      end

      context.article = @article
      context.notice = notice
    else
      context.article = @article
      context.fail!
    end
  end

  private

  def gis_truncated?(dec: GIS_DECIMAL_PRECISION)
    return unless @article_params[:latitude] || @article_params[:longitude]

    lat = @article_params[:latitude].split('.')
    lon = @article_params[:longitude].split('.')

    lat_dec = lat.length == 2 ? lat.last.length : 0
    lon_dec = lon.length == 2 ? lon.last.length : 0

    lat_dec > dec || lon_dec > dec
  end
end
