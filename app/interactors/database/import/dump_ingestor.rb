class Database::Import::DumpIngestor < Database::Base
  def initialize(path:)
    @path = path

    super
  end

  def perform
    import_assets

    RECORDS.each_key do |record_name|
      import_dump(record_name)
    end
  end

  private

  def import_dump(table_name)
    records = []
    rows = YAML.load_file(path_to_dump(table_name))

    rows.each do |row|
      if row['metadata'].present?
        metadata_str = row['metadata'] == "--- {}\n" ? '{}' : row['metadata']
        row['metadata'] = JSON.parse(metadata_str)
      end

      new_record = RECORDS[table_name].new(row)
      if table_name != 'pages' && RECORDS_WITH_ASSETS.keys.include?(table_name)
        picture_path = Rails.root.join(@path, RECORDS_WITH_ASSETS[table_name], new_record.id.to_s, row['picture'] || '')

        if File.file?(picture_path)
          File.open(picture_path) do |file|
            new_record.picture = file
            new_record.write_picture_identifier
          end
        end
      end

      records << new_record
    end

    RECORDS[table_name].import records, validate: false

    return unless table_name != 'pages' && RECORDS_WITH_ASSETS.keys.include?(table_name)

    records.each(&:store_picture!)
  end

  def import_assets
    source_path = Rails.root.join(@path, 'public')
    destination_path = Rails.root.join('public')

    FileUtils.cp_r("#{source_path}/.", destination_path)
  end

  def path_to_dump(record_name)
    "#{@path}/#{record_name}.yml"
  end
end
