class Article::Update < ApplicationInteractor
  attr_accessor :article, :notice

  def initialize(article:, article_params:, user:)
    @article        = article
    @article_params = article_params
    @user           = user

    super
  end

  def perform
    old_title = @article.title
    @article.attributes = @article_params.except(:category_ids)
    categories = Category.where(id: @article_params[:category_ids])
    @article.categories = categories

    if @article.save
      if old_title != @article.title
        Article::RenameJob.perform_later(
          user_id: @user.id,
          article_id: @article.id,
          old_name: old_title,
          new_name: @article.title
        )
      end

      @notice = I18n.t('article.update.subject_successfully_updated')
      if gis_truncated?
        @notice << I18n.t('article.update.gis_coordinates_truncated', precision: GIS_DECIMAL_PRECISION,
                                                                      count: GIS_DECIMAL_PRECISION)
      end
    else
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
