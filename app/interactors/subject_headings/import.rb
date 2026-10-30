require 'csv'
require 'digest'

class SubjectHeadings::Import
  class ImportError < StandardError; end
  MAX_REPORT_BYTES = 16.megabytes - 1
  MAX_BYTES = 5.megabytes
  MAX_ROWS = 10_000

  def self.key(heading, uri)
    # Only one final period is ignored. No pluralization, case folding or
    # subdivision rewriting. Different identifiers remain separate options.
    Digest::SHA256.hexdigest([heading.sub(/\.(?=\z)/, ''), uri.to_s].to_json)
  end

  def initialize(field:, upload:, instructions: nil)
    @field, @upload, @instructions = field, upload, instructions
  end

  def call
    raise ImportError, 'This field is not a subject-heading metadata field.' unless @field.subject_headings?
    raise ImportError, 'Choose a CSV file.' unless @upload.respond_to?(:read) && @upload.respond_to?(:original_filename)
    raise ImportError, 'CSV or report must be smaller than 16 MB.' if @upload.size > MAX_REPORT_BYTES

    content = @upload.read(MAX_REPORT_BYTES + 1).to_s.dup.force_encoding(Encoding::UTF_8)
    raise ImportError, 'CSV or report must be smaller than 16 MB.' if content.bytesize > MAX_REPORT_BYTES
    raise ImportError, 'CSV must use UTF-8 encoding.' unless content.valid_encoding?
    raise ImportError, 'CSV must not contain null bytes.' if content.include?("\0")

    content = content.delete_prefix("\uFEFF")
    csv = CSV.new(content, headers: true, skip_blanks: true)
    rows = []
    csv.each do |row|
      raise ImportError, 'CSV requires a heading column.' unless row.headers.include?('heading')
      next if row.fields.all?(&:blank?)
      heading, uri = row['heading'].to_s, row['uri'].to_s
      if (SubjectHeadings::Report::HEADERS - row.headers).empty?
        heading, uri = [heading, uri].map { |v| SubjectHeadings::Report.import_cell(v) }
      end
      heading, uri = heading.strip, uri.strip.presence
      raise ImportError, "Row #{csv.lineno}: heading is blank." if heading.blank?
      raise ImportError, "Row #{csv.lineno}: heading or URI exceeds 1,000 characters." if heading.length > 1000 || uri.to_s.length > 1000
      if uri && !(uri =~ %r{\Ahttps?://[^\s]+\z})
        raise ImportError, "Row #{csv.lineno}: uri must be an HTTP or HTTPS URI."
      end
      rows << { 'heading' => heading, 'uri' => uri }
      raise ImportError, 'CSV may contain at most 10,000 headings.' if rows.size > MAX_ROWS
    end
    raise ImportError, 'CSV requires a heading column.' unless csv.headers.is_a?(Array) && csv.headers.include?('heading')
    report_upload = (SubjectHeadings::Report::HEADERS - csv.headers).empty?
    raise ImportError, 'CSV must be 5 MB or smaller (reports may be up to 16 MB).' if !report_upload && content.bytesize > MAX_BYTES
    active_bytes = rows.sum { |row| row['heading'].bytesize + row['uri'].to_s.bytesize }
    raise ImportError, 'Active vocabulary must be 5 MB or smaller.' if active_bytes > MAX_BYTES
    raise ImportError, 'CSV contains no usable headings.' if rows.empty?

    @field.with_lock do
      @field.subject_heading_inventory&.destroy!
      inventory = @field.create_subject_heading_inventory!(
        filename: File.basename(@upload.original_filename.to_s).truncate(255),
        row_count: rows.size, source_rows: rows
      )
      unique = rows.uniq { |row| self.class.key(row['heading'], row['uri']) }
      inventory.subject_headings.insert_all!(unique.map do |row|
        row.merge('normalized_key' => self.class.key(row['heading'], row['uri']))
      end)
      @field.update!(subject_heading_instructions: @instructions) unless @instructions.nil?
      inventory
    end
  rescue CSV::MalformedCSVError, ArgumentError => e
    raise ImportError, "Malformed CSV: #{e.message}"
  end
end
