class Work::Export::Printable < ApplicationInteractor
  attr_accessor :format, :content_type, :file

  PDF_ENGINE = 'lualatex'
  PRINTABLE_PATH = Rails.root.join('tmp', 'printable')

  def initialize(work:, format:, edition:, include_metadata:, include_contributors:, include_notes:, preserve_lb:, page_ids: :all, time: Time.now)
    @work = work
    @format = format
    @edition = edition
    @include_metadata = include_metadata
    @include_contributors = include_contributors
    @include_notes = include_notes
    @preserve_lb = preserve_lb
    @page_ids = page_ids
    @time = time

    super
  end

  def perform
    sanitize_format

    export_path = PRINTABLE_PATH.join(time_stub)
    FileUtils.mkdir_p(export_path)

    tex_file = export_path.join(tex_filename)
    @file = export_path.join(filename)
    log_file = export_path.join(log_filename)

    File.open(tex_file, 'w') { |f| f.write(tex_string) }

    command = [
      'pandoc',
      tex_file.to_s,
      '-o', @file.to_s,
      '--from=latex+raw_tex',
      "--to=#{@format}",
      "--pdf-engine=#{PDF_ENGINE}",
      "--lua-filter=#{Rails.root.join('lib', 'pandoc', 'ftp_filters.lua')}",
      '--verbose'
    ]

    success = File.open(log_file, 'w') do |log|
      system(*command, out: log, err: log)
    end

    raise "Pandoc conversion failed! See log: #{log_file}" unless success
  end

  def log_filename
    @log_filename ||= "#{@work.slug.gsub('-', '_')}_#{time_stub}.log"
  end

  def tex_filename
    @tex_filename ||= "#{@work.slug.gsub('-', '_')}_#{time_stub}.tex"
  end

  def filename
    @filename ||= "#{@work.slug.gsub('-', '_')}_#{time_stub}.#{@format}"
  end

  def tex_string
    return @tex_string if defined?(@tex_string)

    html_string = ApplicationController.new.render_to_string(
      template: '/export/tex',
      layout: 'printable',
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
        format: @format,
        time: @time
      },
      formats: [:html]
    ).each_line.map(&:strip).join("\n")

    @tex_string = Work::Export::Lib::Utils.html_unescape(html_string)
  end

  private

  def sanitize_format
    format_sym = @format&.downcase&.to_sym
    if [:doc, :docx].include?(format_sym)
      @format = :docx
      @content_type = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    elsif format_sym == :pdf
      @format = :pdf
      @content_type = 'application/pdf'
    elsif format_sym == :html
      @format = :html
      @content_type = 'text/html'
    else
      raise ArgumentError, 'Unsupported Latex Conversion'
    end
  end

  def pages
    return @pages if defined?(@pages)

    @pages = @work.pages.includes(:notes, :ia_leaf, :sc_canvas)

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
