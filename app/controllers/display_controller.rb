class DisplayController < ApplicationController
  include ApplicationHelper
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
    
    # Handle page range parameter
    if params.has_key?(:page_range)
      @page_range = parse_page_range(params[:page_range])
      if @page_range
        @start_page, @end_page = @page_range
        @page_range_filter = true
      end
    end
    
    @total = @work.pages.count
    if @article
      # restrict to pages that include that subject
      redirect_to :action => 'read_all_works', :article_id => @article.id, :page => 1 and return
    else
      # Apply page range filter if specified
      base_pages = @page_range_filter ? @work.pages.where(position: @start_page..@end_page) : @work.pages
      
      if @review == 'review'
        @pages = base_pages.review.order('position').paginate(page: params[:page], per_page: PAGES_PER_SCREEN)
        @count = @pages.count
        @heading = @page_range_filter ? "#{t('.pages_need_review')} (#{@start_page}-#{@end_page})" : t('.pages_need_review')
      elsif @review == 'incomplete'
        @pages = base_pages.incomplete.order('position').paginate(page: params[:page], per_page: PAGES_PER_SCREEN)
        @count = @pages.count
        @heading = @page_range_filter ? "#{t('.pages_need_completion')} (#{@start_page}-#{@end_page})" : t('.pages_need_completion')
      elsif @review == 'transcription'
        @pages = base_pages.needs_transcription.order('position').paginate(page: params[:page], per_page: PAGES_PER_SCREEN)
        @count = @pages.count
        @incomplete_pages = base_pages.needs_completion.order('position').paginate(page: params[:page], per_page: PAGES_PER_SCREEN)
        @incomplete_count = @incomplete_pages.count
        @heading = @page_range_filter ? "#{t('.pages_need_transcription')} (#{@start_page}-#{@end_page})" : t('.pages_need_transcription')
      elsif @review == 'index'
        @pages = base_pages.needs_index.order('position').paginate(page: params[:page], per_page: PAGES_PER_SCREEN)
        @count = @pages.count
        @heading = @page_range_filter ? "#{t('.pages_need_indexing')} (#{@start_page}-#{@end_page})" : t('.pages_need_indexing')
      elsif @review == 'translation'
        @pages = base_pages.needs_translation.order('position').paginate(page: params[:page], per_page: PAGES_PER_SCREEN)
        @count = @pages.count
        @heading = @page_range_filter ? "#{t('.pages_need_translation')} (#{@start_page}-#{@end_page})" : t('.pages_need_translation')
      elsif @review == 'translation_review'
        @pages = base_pages.translation_review.paginate(page: params[:page], per_page: PAGES_PER_SCREEN)
        @count = @pages.count
        @heading = @page_range_filter ? "#{t('.translations_need_review')} (#{@start_page}-#{@end_page})" : t('.translations_need_review')
      elsif @review == 'translation_index'
        @pages = base_pages.needs_translation_index.paginate(page: params[:page], per_page: PAGES_PER_SCREEN)
        @count = @pages.count
        @heading = @page_range_filter ? "#{t('.translations_need_indexing')} (#{@start_page}-#{@end_page})" : t('.translations_need_indexing')
      else
        @pages = base_pages.paginate(page: params[:page], per_page: PAGES_PER_SCREEN)
        @count = @pages.count
        @heading = @page_range_filter ? "#{t('.pages')} (#{@start_page}-#{@end_page})" : t('.pages')
      end
    end
    session[:col_id] = @collection.slug
    
    # Set social media meta tags for work
    unless @work.nil?
      description = view_context.to_snippet(@work.description, length: 200) if @work.description.present?
      description ||= "A document in the #{@work.collection&.title || 'Unknown Collection'} project on FromThePage"
      
      view_context.set_social_media_meta_tags(
        title: @work.title,
        description: description,
        image_url: view_context.work_image_url(@work) || view_context.collection_image_url(@work.collection),
        url: request.original_url,
        type: 'article'
      )
    end
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
    # Set meta information for web crawlers and archival only for pages with content
    if @page.status != 'new'
      @page_title = "#{@page.title || "Page #{@page.position}"} - #{@work.title} - #{@collection.title}"
      @meta_description = "Transcript of #{@page.title || "page #{@page.position}"} from #{@work.title} in the #{@collection.title} collection."
      @meta_keywords = [@work.title, @collection.title, @page.title, "transcript", "transcription", "historical document"].compact.join(", ")
      
      # Generate structured data for better content understanding
      @structured_data = {
        "@context" => "https://schema.org",
        "@type" => "DigitalDocument",
        "name" => @page.title || "Page #{@page.position}",
        "description" => @meta_description,
        "text" => @page.verbatim_transcription_plaintext,
        "inLanguage" => @collection.text_language || "en",
        "isPartOf" => {
          "@type" => "Book",
          "name" => @work.title,
          "author" => @work.author,
          "dateCreated" => @work.document_date,
          "isPartOf" => {
            "@type" => "Collection",
            "name" => @collection.title,
            "description" => to_snippet(@collection.intro_block)
          }
        },
        "url" => request.original_url,
        "dateModified" => @page.updated_at&.iso8601,
        "publisher" => {
          "@type" => "Organization", 
          "name" => @collection.owner&.display_name || "FromThePage"
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

  private

  # Parse page range from parameter like "5-7", "pp5-7", "p5-7"
  def parse_page_range(range_param)
    return nil if range_param.blank?
    
    # Remove optional "pp" or "p" prefix and extract numbers
    clean_range = range_param.gsub(/^pp?/, '')
    
    # Match pattern like "5-7"
    if match = clean_range.match(/^(\d+)-(\d+)$/)
      start_page = match[1].to_i
      end_page = match[2].to_i
      
      # Validate that start is less than or equal to end
      return nil if start_page > end_page || start_page < 1
      
      [start_page, end_page]
    else
      nil
    end
  end
end
