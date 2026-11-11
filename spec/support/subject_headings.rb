module SubjectHeadingSpecHelpers
  def heading_upload(content, filename = 'headings.csv')
    io = StringIO.new(content)
    io.define_singleton_method(:original_filename) { filename }
    io
  end

  def import_headings(field, content = "heading,uri\nAgriculture,https://id.loc.gov/authorities/subjects/sh85002415\n", **options)
    SubjectHeadings::Import.new(field: field, upload: heading_upload(content), **options).call
  end

  # A validation record for the field without queueing the background job.
  def validation_for(field, content = "heading,uri\nAgriculture,https://id.loc.gov/authorities/subjects/sh85002415\n", **attributes)
    rows = SubjectHeadings::Import.parse(heading_upload(content))
    unique = SubjectHeadings::Import.unique(rows)
    field.subject_heading_validation&.destroy!
    field.create_subject_heading_validation!({ filename: 'headings.csv', row_count: rows.size, source_rows: unique,
      total_count: unique.size, status: 'queued', token: SecureRandom.uuid }.merge(attributes))
  end
end

RSpec.configure do |config|
  config.include SubjectHeadingSpecHelpers
  config.around(:each, :subject_headings) do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end
