class Work::Export::GroverPrintable < ApplicationInteractor
  attr_accessor :file

  def initialize(work:, edition:, include_metadata:, include_contributors:, include_notes:, preserve_lb:, source: :human_only, prepend_ai_warnings: false, page_ids: :all, time: Time.now)
    @work = work
    @edition = edition
    @include_metadata = include_metadata
    @include_contributors = include_contributors
    @include_notes = include_notes
    @preserve_lb = preserve_lb
    @source = source
    @prepend_ai_warnings = prepend_ai_warnings
    @page_ids = page_ids
    @time = time

    super
  end

  # Puppeteer PDF options that make the export pass Acrobat's accessibility
  # checker: `tagged` emits the PDF structure tree, `outline` generates
  # bookmarks from the document heading outline (large documents are required
  # to have bookmarks).
  PDF_OPTIONS = { tagged: true, outline: true }.freeze

  def perform
    @file = Grover.new(html, **PDF_OPTIONS).to_pdf
  end

  def filename
    @filename ||= "#{@work.slug.gsub('-', '_')}_#{time_stub}.pdf"
  end

  def html
    return @html if defined?(@html)

    @html = ApplicationController.renderer.render(
      template: '/export/grover_pdf',
      layout: 'grover',
      assigns: {
        collection: collection,
        work: @work,
        pages: pages,
        contributor_names: contributor_names,
        edition: @edition,
        include_metadata: @include_metadata,
        include_contributors: @include_contributors,
        include_notes: @include_notes,
        preserve_lb: @preserve_lb,
        source: @source,
        prepend_ai_warnings: @prepend_ai_warnings,
        time: @time,
        flatten_links: false
      }
    )

    @html = Work::Export::TableRegularizer.call(@html)
  end

  private

  def pages
    return @pages if defined?(@pages)

    includes = [:notes, :ia_leaf, :sc_canvas]
    includes << :ai_transcription if @source == :human_and_ai

    @pages = @work.pages.includes(includes)

    @pages = @pages.where(id: @page_ids) unless @page_ids == :all

    @pages
  end

  def collection
    @collection ||= @work.collection
  end

  def contributor_names
    return @contributor_names if defined?(@contributor_names)

    if @edition == 'text_only' || !@include_contributors
      @contributor_names = []

      return @contributor_names
    end

    contributors = User.joins(:deeds).where(deeds: { work_id: @work.id }).
      select('users.*, COUNT(deeds.id) as occurrences').
      group('users.id').
      order('occurrences DESC')

    @contributor_names = contributors.map do |contributor|
      contributor.real_name || contributor.display_name
    end.compact

    @contributor_names
  end

  def time_stub
    @time_stub ||= @time.gmtime.iso8601.gsub(/\D/, '')
  end
end
