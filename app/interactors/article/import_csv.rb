class Article::ImportCsv < ApplicationInteractor
  REQUIRED_HEADERS = [
    'heading',
    'article',
    'uri',
    'category'
  ].freeze

  ADDITIONAL_HEADERS = [
    'begun',
    'bibliography',
    'birth date',
    'death date',
    'disambiguator',
    'ended',
    'latitude',
    'longitude',
    'race description',
    'sex'
  ].freeze

  def initialize(file:, collection:, original_filename:, timestamp: Time.now)
    @file = file
    @collection = collection
    @original_filename = original_filename
    @timestamp = timestamp

    super
  end

  def perform
    csv = Utils::Csv::ReadCsv.perform(@file)

    raise ArgumentError, 'Missing required headers' unless (REQUIRED_HEADERS - csv.headers.map(&:downcase)).empty?

    provenance = + "#{@original_filename} (uploaded #{@timestamp} UTC)"

    csv.each do |row|
      row_hash = row.to_hash.transform_keys(&:downcase)

      # REQUIRED_HEADERS
      title = row_hash['heading']
      article = @collection.articles.find_or_initialize_by(title: title)

      article.assign_attributes(
        provenance: article.provenance || provenance,
        collection_id: @collection.id,
        source_text: row_hash['article'],
        uri: row_hash['uri']
      )

      # ADDITIONAL_HEADERS
      ADDITIONAL_HEADERS.each do |header|
        next unless row_hash.key?(header)
        attr_name = header.tr(' ', '_')
        article[attr_name] = row_hash[header]
      end

      category_title = row_hash['category'].to_s.strip
      if category_title.present?
        category = @collection.categories.find_or_create_by!(title: category_title)
        article.categories << category
      end

      article.save!
    end
  end
end
