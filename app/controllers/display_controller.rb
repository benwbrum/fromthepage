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
      elsif @review == 'incomplete'
        @pages = @work.pages.incomplete.order('position').paginate(page: params[:page], per_page: PAGES_PER_SCREEN)
        @count = @pages.count
        @heading = t('.pages_need_completion')
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

  def display_page
    # Set meta information for web crawlers and archival
    @page_title = "#{@page.title || "Page #{@page.position}"} - #{@work.title} - #{@collection.title}"
    @meta_description = "Transcript of #{@page.title || "page #{@page.position}"} from #{@work.title} in the #{@collection.title} collection."
    @meta_keywords = [@work.title, @collection.title, @page.title, "transcript", "transcription", "historical document"].compact.join(", ")
    
    # Generate structured data for better content understanding
    @structured_data = {
      "@context" => "https://schema.org",
      "@type" => "DigitalDocument",
      "name" => @page.title || "Page #{@page.position}",
      "description" => @meta_description,
      "text" => @page.source_text,
      "inLanguage" => @collection.text_language || "en",
      "isPartOf" => {
        "@type" => "Book",
        "name" => @work.title,
        "author" => @work.author,
        "dateCreated" => @work.document_date,
        "isPartOf" => {
          "@type" => "Collection",
          "name" => @collection.title,
          "description" => @collection.intro_block
        }
      },
      "url" => request.original_url,
      "dateModified" => @page.updated_at&.iso8601,
      "publisher" => {
        "@type" => "Organization", 
        "name" => "FromThePage"
      }
    }
    
    # Add archival-friendly meta tags
    respond_to do |format|
      format.html do
        # Additional headers for better archival
        response.headers['X-Robots-Tag'] = 'index, follow, archive'
      end
    end
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
      @search_attempt = SearchAttempt.find_by(slug: params[:id])
      session[:search_attempt_id] = @search_attempt.id if session[:search_attempt_id] != @search_attempt.id

      # restrict to pages that include that subject
      @collection = @search_attempt.collection || @search_attempt.document_set || @search_attempt.work.collection
      @work = @search_attempt&.work
      if ELASTIC_ENABLED
        search_mode = nil
        search_slug = nil

        if @search_attempt.search_type == "collection"
          if @search_attempt.collection.present?
            search_mode = 'collection'
            search_slug = @search_attempt.collection.slug
          elsif @search_attempt.document_set.present?
            search_mode = 'docset'
            search_slug = @search_attempt.document_set.slug
          end
        elsif @search_attempt.search_type == "work"
          if @search_attempt.work.present?
            search_mode = 'work'
            search_slug = @search_attempt.work.slug
          end
        end

        # TODO: Need metrics tracking from new_landing search
        # Redirect to "findaproject" tabbed search results
        redirect_to controller: 'dashboard',
                    action: 'landing_page',
                    search: @search_attempt.query,
                    mode: search_mode,
                    slug: search_slug
      else
        pages = @search_attempt.query_results
        @pages = pages.paginate(page: params[:page])
      end
      @search_string = params[:id].split('-')[0...-1].join(' ')
    end
    logger.debug "DEBUG #{@search_string}"
  end
end
