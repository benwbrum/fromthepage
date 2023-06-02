class DisplayController < ApplicationController
  public :render_to_string

  protect_from_forgery :except => [:set_note_body]

  PAGES_PER_SCREEN = 5

  def read_work
    if params.has_key?(:work_id)
      @work = Work.friendly.find(params[:work_id])
    elsif params.has_key?(:id)
      @work = Work.friendly.find(params[:id])
    elsif params.has_key?(:url)
      @work = Work.find_by_id(params[:url][:work_id])
    end
    if params.has_key?(:needs_review)
      @review = params[:needs_review]
    end
    @total = @work.pages.count
    if @article
      # restrict to pages that include that subject
      redirect_to :action => 'read_all_works', :article_id => @article.id, :page => 1 and return
    else
      if @review == 'review'
        @pages = @work.pages.review.order('position').paginate(page: params[:page], per_page: PAGES_PER_SCREEN)
        @count = @pages.count
        @heading = t('.pages_need_review')
      elsif @review == 'transcription'
        @pages = @work.pages.needs_transcription.order('position').paginate(page: params[:page], per_page: PAGES_PER_SCREEN)
        @count = @pages.count
        @incomplete_pages = @work.pages.needs_completion.order('position').paginate(page: params[:page], per_page: PAGES_PER_SCREEN)
        @incomplete_count = @incomplete_pages.count
        @heading = t('.pages_need_transcription')
      elsif @review == 'index'
        @pages = @work.pages.needs_index.order('position').paginate(page: params[:page], per_page: PAGES_PER_SCREEN)
        @count = @pages.count
        @heading = t('.pages_need_indexing')
      elsif @review == 'translation'
        @pages = @work.pages.needs_translation.order('position').paginate(page: params[:page], per_page: PAGES_PER_SCREEN)
        @count = @pages.count
        @heading = t('.pages_need_translation')
      elsif @review == 'translation_review'
        @pages = @work.pages.translation_review.paginate(page: params[:page], per_page: PAGES_PER_SCREEN)
        @count = @pages.count
        @heading = t('.translations_need_review')
      elsif @review == 'translation_index'
        @pages = @work.pages.needs_translation_index.paginate(page: params[:page], per_page: PAGES_PER_SCREEN)
        @count = @pages.count
        @heading = t('.translations_need_indexing')
      else
        @pages = @work.pages.paginate(page: params[:page], per_page: PAGES_PER_SCREEN)
        @count = @pages.count
        @heading = t('.pages')
      end
    end
    session[:col_id] = @collection.slug
  end

  def read_all_works
    if @article
      # restrict to pages that include that subject
      @pages = Page.order('work_id, position').joins('INNER JOIN page_article_links pal ON pages.id = pal.page_id').where([ 'pal.article_id = ?', @article.id ]).where(work_id: @collection.works.ids).paginate(page: params[:page], per_page: PAGES_PER_SCREEN)
      @pages.distinct!
      @heading = t('.pages_that_mention', article: @article.title)
    else
      @pages = Page.paginate :all, :page => params[:page],
                                        :order => 'work_id, position',
                                        :per_page => 5
      @heading = t('.pages')
    end
    session[:col_id] = @collection.slug
  end

  def search
    redirect_to paged_search_path(request.params)
  end

  def paged_search
    if @article
      render plain: "This functionality has been disabled.  Please contact support@frothepage.com if you need it."
      return

      session[:col_id] = @collection.slug
      # get the unique search terms
      terms = []
      @search_string = ""
      @article.page_article_links.each do |link|
        terms << link.display_text.gsub(/\s+/, ' ')
      end
      terms.uniq!
      # process them for display and search
      terms.each do |term|
        # don't add required text
        if term.match(/ /)
          @search_string += "\"#{term}\" "
        else
          @search_string += term + "* "
        end
      end
      if params[:unlinked_only]
        conditions =
          ["MATCH(search_text) AGAINST(? IN BOOLEAN MODE)"+
          " AND pages.id not in "+
          "    (SELECT page_id FROM page_article_links WHERE article_id = ?)",
          @search_string,
          @article.id]

      else
        conditions =
          ["MATCH(search_text) AGAINST(? IN BOOLEAN MODE)",
          @search_string]
      end
      @pages = Page.order('work_id, position').joins(:work).where(work_id: @collection.works.ids).where(conditions).paginate(page: params[:page])
    else
      # restrict to pages that include that subject
      if params[:work_id]
        @search_work_string = sanitize_and_format_search_string(params[:search_work_string])
        pages = search_pages_by_work(params[:work_id], @search_work_string)
      else
        @search_string = sanitize_and_format_search_string(params[:search_string])
        pages = search_pages_in_collection(@search_string)
      end
      @pages = pages.paginate(page: params[:page])
    end
    logger.debug "DEBUG #{@search_string}"
  end
  
  private

  def sanitize_and_format_search_string(search_string)
    return CGI::escapeHTML(search_string) if search_string.present?

    ''
  end

  def search_pages_by_work(work_id, search_work_string)
    return Page.none unless work_id.present? && search_work_string.present?

    formatted_search_string = format_search_string(search_work_string)
    Page.order('work_id, position')
        .joins(:work)
        .where(work_id: work_id)
        .where("MATCH(search_text) AGAINST(? IN BOOLEAN MODE)", formatted_search_string)
  end

  def search_pages_in_collection(search_string)
    return Page.none unless search_string.present?

    formatted_search_string = format_search_string(search_string)
    Page.order('work_id, position')
        .joins(:work)
        .where(work_id: @collection.works.ids)
        .where("MATCH(search_text) AGAINST(? IN BOOLEAN MODE)", formatted_search_string)
  end

  def format_search_string(search_string)
    # convert 'natural' search strings unless they're precise
    return search_string if search_string.match(/["+-]/)

    search_string.gsub!(/\s+/, ' ')
    "+\"#{search_string}\""
  end
end
