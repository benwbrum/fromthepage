# == Schema Information
#
# Table name: works
#
#  id                              :integer          not null, primary key
#  author                          :string(255)
#  created_on                      :datetime
#  description                     :text(16777215)
#  description_status              :string(255)      default("undescribed")
#  document_date                   :string(255)
#  document_history                :text(16777215)
#  editorial_notes                 :text(65535)
#  featured_page                   :integer
#  genre                           :string(255)
#  identifier                      :string(255)
#  in_scope                        :boolean          default(TRUE)
#  location_of_composition         :string(255)
#  metadata_description            :text(65535)
#  most_recent_deed_created_at     :datetime
#  ocr_correction                  :boolean          default(FALSE)
#  original_metadata               :text(65535)
#  pages_are_meaningful            :boolean          default(TRUE)
#  permission_description          :text(16777215)
#  physical_description            :text(16777215)
#  picture                         :string(255)
#  recipient                       :string(255)
#  restrict_scribes                :boolean          default(FALSE)
#  scribes_can_edit_titles         :boolean          default(FALSE)
#  searchable_metadata             :text(65535)
#  slug                            :string(255)
#  source_box_folder               :string(255)
#  source_collection_name          :string(255)
#  source_location                 :string(255)
#  supports_translation            :boolean          default(FALSE)
#  title                           :string(255)
#  transcription_conventions       :text(16777215)
#  transcription_version           :integer          default(0)
#  translation_instructions        :text(65535)
#  uploaded_filename               :string(255)
#  collection_id                   :integer
#  metadata_description_version_id :integer
#  next_untranscribed_page_id      :integer
#  owner_user_id                   :integer
#
# Indexes
#
#  index_works_on_collection_id                    (collection_id)
#  index_works_on_metadata_description_version_id  (metadata_description_version_id)
#  index_works_on_owner_user_id                    (owner_user_id)
#  index_works_on_slug                             (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (metadata_description_version_id => metadata_description_versions.id)
#
class Work < ApplicationRecord
  require 'elastic_util'

  include ElasticDelta
  extend FriendlyId
  friendly_id :slug_candidates, :use => [:slugged, :history]

  PUBLIC_ATTRIBUTES =
    ["title",
     "description",
     "created_on",
     "physical_description",
     "document_history",
     "permission_description",
     "location_of_composition",
     "author",
     "recipient",
     "identifier",
     "genre",
     "source_location",
     "source_collection_name",
     "source_box_folder",
     "in_scope",
     "editorial_notes",
     "document_date",
     "uploaded_filename"]

  before_destroy :cleanup_images # must precede pages association
  has_many :pages, -> { order 'position' }, :dependent => :destroy, :after_add => :update_statistic, :after_remove => :update_statistic
  belongs_to :owner, :class_name => 'User', :foreign_key => 'owner_user_id', optional: true

  belongs_to :next_untranscribed_page, foreign_key: 'next_untranscribed_page_id', class_name: "Page", optional: true
  has_many :untranscribed_pages, -> { needs_transcription }, class_name: "Page"

  belongs_to :collection, counter_cache: :works_count, optional: true
  has_many :deeds, -> { order 'created_at DESC' }, :dependent => :destroy
  has_many :notes #, through: :pages
  has_one :ia_work, :dependent => :destroy
  has_one :sc_manifest, :dependent => :destroy
  has_one :work_statistic, :dependent => :destroy
  has_many :sections, -> { order 'position' }, :dependent => :destroy
  has_many :table_cells, :dependent => :destroy

  has_and_belongs_to_many :scribes, :class_name => 'User', :join_table => :transcribe_authorizations

  has_many :document_set_works
  has_many :document_sets, through: :document_set_works
  has_one :work_facet, :dependent => :destroy
  has_many :bulk_exports, :dependent => :delete_all
  has_many :metadata_description_versions, -> { order 'version_number DESC' }, :dependent => :destroy

  before_save :update_derivatives

  after_save :create_version
  after_save :update_statistic
  after_save :update_next_untranscribed_pages

  after_create :alert_bento

  validates :title, presence: true, length: { minimum: 3, maximum: 255 }
  validates :slug, uniqueness: { case_sensitive: true }, format: { with: /[-_[:alpha:]]/ }
  validates :description, html: true, length: { maximum: 16.megabytes - 1 }
  validate :document_date_is_edtf

  mount_uploader :picture, PictureUploader

  scope :unrestricted, -> { where(restrict_scribes: false)}
  scope :restricted, -> { where(restrict_scribes: true)}
  scope :order_by_recent_activity, -> { joins(:deeds).reorder('deeds.created_at DESC').distinct }
  scope :order_by_recent_inactivity, -> { joins(:deeds).reorder('deeds.created_at ASC').distinct }
  scope :order_by_completed, -> { joins(:work_statistic).reorder('work_statistics.complete DESC')}
  scope :order_by_incomplete, -> { joins(:work_statistic).reorder('work_statistics.complete ASC')}
  scope :order_by_translation_completed, -> { joins(:work_statistic).reorder('work_statistics.translation_complete DESC')}
  scope :incomplete_transcription, -> { where(supports_translation: false).joins(:work_statistic).where.not(work_statistics: {complete: 100})}
  scope :incomplete_translation, -> { where(supports_translation: true).joins(:work_statistic).where.not(work_statistics: {translation_complete: 100})}
  scope :incomplete_description, -> { where(description_status: DescriptionStatus::NEEDS_WORK) }

  scope :ocr_enabled, -> { where(ocr_correction: true) }
  scope :ocr_disabled, -> { where(ocr_correction: false) }
  after_commit :save_metadata, on: [:create, :update]

  module DescriptionStatus
    UNDESCRIBED = 'undescribed'
    NEEDS_REVIEW = 'needsreview'
    INCOMPLETE = 'incomplete'
    DESCRIBED = 'described'
    NEEDS_WORK = [
      UNDESCRIBED,
      INCOMPLETE
    ]
  end



  module TitleStyle
    REPLACE = 'REPLACE'

    PAGE_ARABIC = "Page #{REPLACE}"
    PAGE_ROMAN = "Page #{REPLACE}"
    ENVELOPE = "Envelope (#{REPLACE})"
    COVER = 'Cover (#{REPLACE})'
    ENCLOSURE = 'Enclosure REPLACE'
    DEFAULT = PAGE_ARABIC

    def self.render(style, number)
      style.sub(REPLACE, number.to_s)
    end

    def self.style_from_prior_title(title)
      PAGE_ARABIC
    end
    def self.number_from_prior_title(style, title)
      regex_string = style.sub('REPLACE', "(\\d+)")
      md = title.match(/#{regex_string}/)

      if md
        md.captures.first
      else
        nil
      end
    end
  end

  def as_indexed_json
    # Error handling for data that is missing parent relationships
    # Some works have collection_id 0, others have ID's that don't exist
    # Return object with error set so indexer knows to skip
    if !self.collection.present?
      return {
        indexing_error: true
      }
    end

    return {
      _id: self.id,
      is_public: !self.collection&.restricted || self.document_sets.where(:is_public => true).exists?,
      collection_id: self.collection&.id,
      docset_id: self.document_sets.pluck(:id),
      owner_user_id: self.owner_user_id,
      title: self.title,
      searchable_metadata: self.searchable_metadata
    }
  end

  def self.es_match_query(query, user)
    blocked_collections = []
    collection_collabs = []
    docset_collabs= []

    if !user.nil?
      blocked_collections = user.blocked_collections.pluck(:id)
      collection_collabs = user.collection_collaborations.pluck(:id)
      docset_collabs = user.document_set_collaborations.pluck(:id)
    end

    search_fields = [
      "title^2",
      "searchable_metadata.identifier_whitespace^1.5",
      "searchable_metadata"
    ]

    return {
      bool: {
        must: {
          simple_query_string: {
            query: query,
            fields: search_fields
          }
        },
        filter: [
          {
            bool: {
              must_not: [
                { terms: {collection_id: blocked_collections} }
              ],
              # At least one of the following must be true
              should: [
                { term: {is_public: true} },
                { term: {owner_user_id: user.nil? ? -1 : user.id} },
                { terms: {collection_id: collection_collabs} },
                { terms: {docset_id: docset_collabs} },
              ]
            }
          },
          # Need index filter for cross collection search
          {prefix: {_index: "ftp_work"}}
        ]
      }
    }
  end

  def update_derivatives
    # searchable_metadata is currently the only derivative
    metadata_hash = self.merge_metadata(true)
    value_array = metadata_hash.map {|e| e['value']}

    self.searchable_metadata = value_array.flatten.join("\n\n")
  end

  def merge_metadata(include_user=false)
    metadata = []
    if self.original_metadata
      metadata += JSON[self.original_metadata]
    end
    work_metadata = self.attributes.select{|k,v| PUBLIC_ATTRIBUTES.include?(k) && !v.blank?}

    work_metadata.each_pair { |label,value| metadata << { "label" => label.titleize, "value" => value.to_s } }

    if include_user && !self.metadata_description.blank?
      metadata += JSON[self.metadata_description]
    end

    metadata
  end


  def access_object(user)
    if self.collection.show_to?(user)
      # public collection or collection that has authorized access
      self.collection
    elsif self.collection.supports_document_sets
      # private collection whcih might have document sets that grant access
      alternative_set = self.document_sets.where(:is_public => true).first
      if alternative_set
        alternative_set
      else
        # is there a private document set which this user has been given access to?
        nil
      end
    else
      nil #false
    end
  end

  def verbatim_transcription_plaintext
    self.pages.select{ |page| !page.status_blank? }.map{ |page| page.verbatim_transcription_plaintext }.join("\n\n\n")
  end

  def verbatim_translation_plaintext
    self.pages.map { |page| page.verbatim_translation_plaintext}.join("\n\n\n")
  end

  def emended_transcription_plaintext
    self.pages.select{|page| !page.status_blank? }.map { |page| page.emended_transcription_plaintext}.join("\n\n\n")
  end

  def emended_translation_plaintext
    self.pages.map { |page| page.emended_translation_plaintext}.join("\n\n\n")
  end

  def searchable_plaintext
    self.pages.select{|page| !page.status_blank? }.map { |page| page.search_text}.join("\n\n\n")
  end

  def suggest_next_page_title
    if self.pages.count == 0
      TitleStyle::render(TitleStyle::DEFAULT, 1)
    else
      prior_title = self.pages.last.title
      style = TitleStyle::style_from_prior_title(prior_title)
      number = TitleStyle::number_from_prior_title(style, prior_title)

      next_number = number ? number.to_i + 1 : self.pages.count + 1

      TitleStyle::render(style, next_number)
    end
  end

  def revert
  end

  def articles
    Article.joins(:page_article_links).where(page_article_links: {page_id: self.pages.ids}).distinct
  end


  def document_date=(date_as_edtf)
    if date_as_edtf.respond_to? :to_edtf
      self[:document_date] = date_as_edtf.to_edtf
    else
      # the edtf-ruby gem has some gaps in coverage for e.g. seasons
      self[:document_date] = date_as_edtf.to_s
    end
  end

  def document_date
    date = Date.edtf(self[:document_date])

    if self[:document_date].nil? # there is no document date
      return nil
    elsif date.nil? # the document date is invalid
      return self[:document_date]
    # assign date precision based on length of document_date string (edtf-ruby does not do this automatically)
    elsif self[:document_date].length == 7 # YYYY-MM
      date.month_precision!
    elsif self[:document_date].length == 4 and not self[:document_date].include? "x" # YYYY
      date.year_precision!
    end

    return date.edtf
  end

  def document_date_is_edtf
    if self[:document_date].present?
      if Date.edtf(self[:document_date]).nil?
        errors.add(:document_date, 'must be in EDTF format')
      end
    end
  end

  def update_deed_collection
    deeds.where.not(:collection_id => collection_id).update_all(:collection_id => collection_id)
  end

  # TODO make not awful
  def reviews
    my_reviews = []
    for page in self.pages
      for comment in page.comments
        my_reviews << comment if comment.comment_type == 'review'
      end
    end
    return my_reviews
  end

  # TODO make not awful (denormalize work_id, collection_id; use legitimate finds)
  def recent_annotations
    my_annotations = []
    for page in self.pages
      for comment in page.comments
        my_annotations << comment if comment.comment_type == 'annotation'
      end
    end
    my_annotations.sort! { |a,b| b.created_at <=> a.created_at }
    return my_annotations[0..9]
  end

  def update_statistic(changed_page=nil) #association callbacks pass the page being added/removed, but we don't care
    unless self.work_statistic
      self.work_statistic = WorkStatistic.new
    end
    self.work_statistic.recalculate
  end

  def set_transcription_conventions
    if self.transcription_conventions.present?
      self.transcription_conventions
    else
      self.collection.transcription_conventions
    end
  end

  def cleanup_images
    absolute_filenames = pages.map { |page| [page.base_image, page.thumbnail_filename]}.flatten
    modern_filenames = absolute_filenames.map{|fn| fn.sub(/^.*uploaded/, File.join(Rails.root, "public", "images", "uploaded"))}
    modern_filenames.each do |fn|
      if File.exist?(fn)
        File.delete(fn) if File.exist?(fn)
      else
        logger.debug "File #{fn} does not exist"
      end
    end
    new_dir_name = File.join(Rails.root, "public", "images", "uploaded", self.id.to_s)
    if Dir.exist?(new_dir_name)
      # test to see if the directory is empty
      if Dir.glob(File.join(new_dir_name, "*")).empty?
        # if it is, delete it
        Dir.rmdir(new_dir_name)
      else
        logger.debug "Directory #{new_dir_name} is not empty; contents are #{Dir.glob(File.join(new_dir_name, "*")).sort.join(', ')}"
      end
    end
  end

  def completed
    if self.supports_translation == true
      self.work_statistic.translation_complete
    else
      self.work_statistic.complete
    end
  end

  def untranscribed?
    self.work_statistic.pct_transcribed == 0
  end

  def thumbnail
    if !self.picture.blank?
      self.picture_url(:thumb)
    else
      unless self.pages.count == 0
        if self.featured_page.nil?
          set_featured_page
        end
        featured_page = Page.find_by(id: self.featured_page)
        featured_page.thumbnail_url
      else
        return nil
      end
    end
  end

  def normalize_friendly_id(string)
    string = string.truncate(230, separator: ' ', omission: '')
    unless string.match? /[[:alpha:]]/
      string = "work-#{string}"
    end
    super.gsub('_', '-')
  end


  def slug_candidates
    if self.slug
      [:slug]
    else
      [
        :title,
        [:title, :id]
      ]
    end
  end

  def should_generate_new_friendly_id?
    slug_changed? || super
  end

  def set_featured_page
      num = (self.pages.count/3).round
      page = self.pages.offset(num).first
      self.update_columns(featured_page: page.id)
  end

  def field_based
    self.collection.field_based
  end

  def supports_indexing?
    collection.subjects_disabled == false
  end

  def update_next_untranscribed_pages
    set_next_untranscribed_page
    collection&.set_next_untranscribed_page

    unless document_sets.empty?
      document_sets.each do |ds|
        ds.set_next_untranscribed_page
      end
    end
  end

  def set_next_untranscribed_page
    next_page = untranscribed_pages.order("position ASC").first
    page_id = next_page.nil? ? nil : next_page.id
    update_columns(next_untranscribed_page_id: page_id)
  end

  def has_untranscribed_pages?
    next_untranscribed_page.present?
  end

  def process_fields(field_cells)
    metadata_fields = []
    # new_table_cells = []
    unless field_cells.blank?
      field_cells.each do |id, cell_data|
        field = TranscriptionField.find(id.to_i)
        input_type = field.input_type

        # TODO don't save instruction or description types

        element = {}
        element['transcription_field_id'] = id.to_i


        cell_data.each do |key, value|
          element['label'] = key

          element['value'] = value
        end

        metadata_fields << element
      end
    end
    self.metadata_description = metadata_fields.to_json
    self.description_status = DescriptionStatus::DESCRIBED
    # add this to versions here
    metadata_fields
  end

  def create_version
    # only do this if metadata description has saved
    if saved_change_to_metadata_description?
      version = MetadataDescriptionVersion.new
      version.work = self
      version.metadata_description = self.metadata_description
      unless User.current_user.nil?
        version.user = User.current_user
      else
        version.user = User.find_by(id: self.work.owner_user_id)
      end

      previous_version = MetadataDescriptionVersion.where("work_id = ?", self.id).order("version_number DESC").first
      if previous_version
        version.version_number = previous_version.version_number + 1
      else
        version.version_number = 1
      end
      version.save!
    end
  end

  def alert_bento
    if defined?(BENTO_ENABLED) && BENTO_ENABLED
      if self.owner.owner_works.count == 1
        $bento.track(identity: {email: self.owner.email}, event: '$action', details: {action_information: "first-upload"})
      end
    end
  end

  def save_metadata
    # this is costly, so only execute if the relevant value has actually changed
    if self.original_metadata && self.original_metadata_previously_changed? # this is costly, so only
      om = JSON.parse(self.original_metadata)
      om.each do |m|
        unless m['label'].blank?
          label = m['label']
          if label.is_a? Array
            label=label.first['@value']
          end

          collection = self.collection

          unless self.collection.nil?
            mc = collection.metadata_coverages.build

            # check that record exist
            test = collection.metadata_coverages.where(key: label).first
            # increment count field if a record is returned
            if test
              test.count+= 1
              test.save
            else
              mc.key = label.to_sym
              mc.count = 1
              mc.save
              mc.create_facet_config(metadata_coverage_id: mc.collection_id)
            end
          end
        end
      end

      # now update the work_facet
      FacetConfig.update_facets(self)
    end
  end

  def user_can_transcribe?(user)
    !self.restrict_scribes || user&.like_owner?(self) || self.scribes.include?(user)
  end
end
