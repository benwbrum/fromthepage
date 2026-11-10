require 'iiif_http'

# Copies the text of a IIIF v3 manifest's canvas annotations (e.g. the DjVu OCR
# the Internet Archive publishes) into the source text of a work's pages.
#
# Pages that already have text are skipped, so a retried run only fetches what
# a failed run missed.  Raises after processing every page if any page failed.
#
# @params work: required
# @params user: required
class Work::ImportAnnotationText < ApplicationInteractor
  attr_accessor :imported_page_ids, :failed_page_ids

  def initialize(work:, user:)
    @work = work
    @user = user
    @imported_page_ids = []
    @failed_page_ids = []

    super
  end

  def perform
    raise ArgumentError, 'User may not edit this work' unless @user&.like_owner?(@work)

    manifest = IiifHttp.fetch_json(@work.sc_manifest.at_id)
    canvases = Array.wrap(manifest['items']).index_by { |canvas| canvas['id'] }

    @work.pages.includes(:sc_canvas).find_each do |page|
      next if page.source_text.present? || page.sc_canvas.nil?

      canvas = canvases[page.sc_canvas.sc_canvas_id]
      next if canvas.nil?

      import_page(page, canvas)
    end

    raise "Could not import annotation text for pages #{@failed_page_ids.join(', ')}" if @failed_page_ids.any?
  end

  private

  def import_page(page, canvas)
    text = ScManifest.v3_annotation_pages(canvas).map { |annotation_page| text_from(annotation_page) }.compact_blank.join("\n")
    return if text.blank?

    page.source_text = text.encode(xml: :text)
    page.save!
    @imported_page_ids << page.id
  rescue StandardError => e
    Rails.logger.error("Annotation text import failed for page #{page.id}: #{e.message}")
    @failed_page_ids << page.id
  end

  def text_from(annotation_page)
    # referenced annotation pages carry only an id and type
    annotation_page = IiifHttp.fetch_json(annotation_page['id']) unless annotation_page.key?('items')

    values = Array.wrap(annotation_page['items']).flat_map { |annotation| textual_values(annotation) }

    # Word-level OCR (like IA's DjVu) puts a trailing space on every word except
    # the last one on a line; line- or block-level annotations have none, so
    # either way a value without trailing whitespace ends a line.
    values.map { |value| value.match?(/\s\z/) ? value : "#{value}\n" }.join.gsub(/[ \t]+$/, '').strip
  end

  def textual_values(annotation)
    return [] if Array.wrap(annotation['motivation']).include?('painting')

    Array.wrap(annotation['body']).filter_map do |body|
      next unless body.is_a?(Hash) && body['type'] == 'TextualBody' && body['value'].is_a?(String)

      body['format'] == 'text/html' ? html_to_text(body['value']) : body['value']
    end
  end

  def html_to_text(html)
    doc = Nokogiri::HTML(html)
    doc.search('br').each { |node| node.replace("\n") }
    doc.text
  end
end
