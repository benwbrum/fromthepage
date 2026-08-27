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
    'short_summary',
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
      category = @collection.categories.find_or_create_by!(title: category_title) if category_title.present?

      save_article(article, title, category)
    end
  end

  private

  # Serialize subject creation within a collection so concurrent imports do not
  # both pass the model validation before inserting. If another process won the
  # race, keep its attributes intact; only add this row's category below.
  def save_article(article, title, category)
    if article.new_record?
      @collection.with_lock do
        article = @collection.articles.find_by(title: title) || article.tap(&:save!)
      end
    else
      article.save!
    end
    article.categories << category if category && !article.categories.exists?(category.id)
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid => error
    raise if error.is_a?(ActiveRecord::RecordInvalid) && !error.record.errors.of_kind?(:title, :taken)

    article = @collection.articles.find_by!(title: title)
    article.categories << category if category && !article.categories.exists?(category.id)
  end
end
