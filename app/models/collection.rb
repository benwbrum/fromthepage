# == Schema Information
#
# Table name: collections
#
#  id                             :integer          not null, primary key
#  alphabetize_works              :boolean          default(TRUE)
#  api_access                     :boolean          default(FALSE)
#  created_on                     :datetime
#  data_entry_type                :string(255)      default("text")
#  default_orientation            :string(255)
#  description_instructions       :text(65535)
#  enable_spellcheck              :boolean          default(FALSE)
#  facets_enabled                 :boolean          default(FALSE)
#  field_based                    :boolean          default(FALSE)
#  footer_block                   :text(16777215)
#  help                           :text(65535)
#  hide_completed                 :boolean          default(TRUE)
#  intro_block                    :text(16777215)
#  is_active                      :boolean          default(TRUE)
#  language                       :string(255)
#  license_key                    :string(255)
#  link_help                      :text(65535)
#  messageboard_slug              :string(255)
#  messageboards_enabled          :boolean
#  most_recent_deed_created_at    :datetime
#  pct_completed                  :integer
#  picture                        :string(255)
#  restricted                     :boolean          default(FALSE)
#  review_type                    :string(255)      default("optional")
#  slug                           :string(255)
#  subjects_disabled              :boolean          default(TRUE)
#  supports_document_sets         :boolean          default(FALSE)
#  text_language                  :string(255)
#  title                          :string(255)
#  transcription_conventions      :text(65535)
#  user_download                  :boolean          default(FALSE)
#  voice_recognition              :boolean          default(FALSE)
#  works_count                    :integer          default(0)
#  next_untranscribed_page_id     :integer
#  owner_user_id                  :integer
#  thredded_messageboard_group_id :bigint
#
# Indexes
#
#  index_collections_on_owner_user_id                   (owner_user_id)
#  index_collections_on_restricted                      (restricted)
#  index_collections_on_slug                            (slug) UNIQUE
#  index_collections_on_thredded_messageboard_group_id  (thredded_messageboard_group_id)
#
# Foreign Keys
#
#  fk_rails_...  (thredded_messageboard_group_id => thredded_messageboard_groups.id)
#
require 'csv'
require 'subject_exporter'
require 'subject_details_exporter'
require 'subject_coocurrence_exporter'
require 'subject_distribution_exporter'

class Collection < ApplicationRecord
  include CollectionStatistic
  include ElasticDelta
  extend FriendlyId
  friendly_id :slug_candidates, :use => [:slugged, :history]
  before_save :uniquify_slug

  has_many :collection_blocks, dependent: :destroy
  has_many :blocked_users, through: :collection_blocks, source: :user
  has_many :works, -> { order 'title' }, :dependent => :destroy #, :order => :position
  has_many :notes, -> { order 'created_at DESC' }, :dependent => :destroy
  has_many :articles, :dependent => :destroy
  has_many :document_sets, -> { order 'title' }, :dependent => :destroy
  has_many :categories, -> { order 'title' }
  has_many :deeds, -> { order 'deeds.created_at DESC' }, :dependent => :destroy
  has_one :sc_collection, :dependent => :destroy
  has_many :transcription_fields, -> { where field_type: TranscriptionField::FieldType::TRANSCRIPTION }, :dependent => :destroy
  has_many :metadata_fields, -> { where field_type: TranscriptionField::FieldType::METADATA }, :class_name => 'TranscriptionField', :dependent => :destroy
  has_many :bulk_exports, :dependent => :destroy
  has_many :editor_buttons, :dependent => :destroy
  has_one :quality_sampling, :dependent => :destroy
  belongs_to :messageboard_group, class_name: 'Thredded::MessageboardGroup', foreign_key: 'thredded_messageboard_group_id', optional: true

  belongs_to :next_untranscribed_page, foreign_key: 'next_untranscribed_page_id', class_name: "Page", optional: true
  has_many :pages, -> { reorder('works.title, pages.position') }, through: :works
  has_many :metadata_coverages, :dependent => :destroy
  has_many :facet_configs, -> { order(input_type: :asc, order: :asc) }, through: :metadata_coverages
  has_many :table_cells, through: :transcription_fields

  belongs_to :owner, :class_name => 'User', :foreign_key => 'owner_user_id', optional: true
  has_and_belongs_to_many :owners, :class_name => 'User', :join_table => :collection_owners
  has_and_belongs_to_many :collaborators, :class_name => 'User', :join_table => :collection_collaborators
  has_and_belongs_to_many :reviewers, :class_name => 'User', :join_table => :collection_reviewers
  has_and_belongs_to_many :tags
  has_many :ahoy_activity_summaries

  validates :title, presence: true, length: { minimum: 3, maximum: 255 }
  validates :intro_block, html: true, length: { maximum: 16.megabytes - 1 }
  validates :footer_block, html: true, length: { maximum: 16.megabytes - 1 }
  validates :slug, format: { with: /[[:alpha:]]/ }

  before_create :set_transcription_conventions
  before_create :set_help
  before_create :set_link_help
  after_create :create_categories
  after_save :set_next_untranscribed_page

  mount_uploader :picture, PictureUploader

  scope :order_by_recent_activity, -> { order(most_recent_deed_created_at: :desc) }
  scope :unrestricted, -> { where(restricted: false)}
  scope :restricted, -> { where(restricted: true)}
  scope :order_by_incomplete, -> { joins(works: :work_statistic).reorder('work_statistics.complete ASC')}
  scope :carousel, -> {where(pct_completed: [nil, 0..90]).where.not(picture: nil).where.not(intro_block: [nil, '']).where(restricted: false).reorder(Arel.sql("RAND()"))}
  scope :has_intro_block, -> { where.not(intro_block: [nil, '']) }
  scope :has_picture, -> { where.not(picture: nil) }
  scope :not_near_complete, -> { where(pct_completed: [nil, 0..90]) }
  scope :not_empty, -> { where.not(works_count: [0, nil]) }


  scope :random_sample, -> (sample_size = 5) do
    carousel
    reorder(Arel.sql("RAND()")) unless sample_size > 1
    limit(sample_size).reorder(Arel.sql("RAND()"))
  end

  module DataEntryType
    TEXT_ONLY = 'text'
    METADATA_ONLY = 'metadata'
    TEXT_AND_METADATA = 'text_and_metadata'
  end

  def as_indexed_json
    return {
      _id: self.id,
      permissions_updated: 0,
      is_public: !self.restricted,
      is_docset: false,
      intro_block: self.intro_block,
      language: self.language,
      owner_user_id: self.owner_user_id,
      owner_display_name: self.owner&.display_name,
      slug: self.slug,
      title: self.title
    }
  end

  def self.es_match_query(query, user = nil)
    blocked_collections = []
    collection_collabs = []
    docset_collabs= []

    if !user.nil?
      blocked_collections = user.blocked_collections.pluck(:id)
      collection_collabs = user.collection_collaborations.pluck(:id)
      docset_collabs = user.document_set_collaborations.pluck(:id)
        .map{ |x| "docset-#{x}" }
    end

    return {
      bool: {
        must: {
          simple_query_string: {
            query: query,
            fields: [
              "title^2",
              "intro_block",
              "slug"
            ]
          }
        },
        filter: [
          {
            bool: {
              must_not: [
                { terms: {_id: blocked_collections} }
              ],
              # At least one of the following must be true
              should: [
                { term: {is_public: true} },
                { term: {owner_user_id: user.nil? ? -1 : user.id} },
                { terms: {_id: collection_collabs} },
                { terms: {_id: docset_collabs} },
              ]
            }
          },
          # Need index filter for cross collection search
          {prefix: {_index: "ftp_collection"}}
        ]
      }
    }
  end

  def text_entry?
    self.data_entry_type == DataEntryType::TEXT_AND_METADATA || self.data_entry_type == DataEntryType::TEXT_ONLY
  end

  def metadata_entry?
    self.data_entry_type == DataEntryType::TEXT_AND_METADATA || self.data_entry_type == DataEntryType::METADATA_ONLY
  end

  def metadata_only_entry?
    self.data_entry_type == DataEntryType::METADATA_ONLY
  end

  def text_and_metadata_entry?
    self.data_entry_type == DataEntryType::TEXT_AND_METADATA
  end

  def subjects_enabled
    !subjects_disabled
  end

  module ReviewType
    OPTIONAL = 'optional'
    REQUIRED = 'required'
    RESTRICTED = 'restricted'
  end

  def pages_needing_review_for_one_off
    all_edits_by_user = self.deeds.where(deed_type: DeedType.transcriptions_or_corrections).group(:user_id).count
    one_off_editors = all_edits_by_user.select{|k,v| v == 1}.map{|k,v| k}
    self.pages.where(status: :needs_review).joins(:current_version).where('page_versions.user_id in (?)', one_off_editors)
  end

  def never_reviewed_users
    users_with_complete_pages = self.deeds.joins(:page).where('pages.status' => Page::COMPLETED_STATUSES).pluck(:user_id).uniq
    users_with_needs_review_pages = self.deeds.joins(:page).where('pages.status' => 'review').pluck(:user_id).uniq
    unreviewed_users = User.find(users_with_needs_review_pages - users_with_complete_pages)
  end

  def review_workflow
    review_type != ReviewType::OPTIONAL
  end



  def enable_messageboards
    if self.messageboard_group.nil?
      self.messageboard_group = Thredded::MessageboardGroup.create!(name: self.title)
      # now create the default messageboards
      Thredded::Messageboard.create!(name: 'General', description: 'General discussion', messageboard_group_id: self.messageboard_group.id)
      Thredded::Messageboard.create!(name: 'Help', messageboard_group_id: self.messageboard_group.id)
    end
    self.messageboards_enabled = true
    self.save!
  end

  def disable_messageboards
    self.messageboards_enabled=false
    self.save!
  end

  def self.access_controlled(user)
    if user.nil?
      Collection.unrestricted
    else
      owned_collections          = user.all_owner_collections.pluck(:id)
      collaborator_collections   = user.collection_collaborations.pluck(:id)
      public_collections         = Collection.unrestricted.pluck(:id)

      Collection.where(:id => owned_collections + collaborator_collections + public_collections)
    end
  end

  def page_metadata_fields
    page_fields = []
    works.each do |w|
      page_fields += w.pages.first.metadata.keys if w.pages.first && w.pages.first.metadata
    end

    page_fields.uniq
  end

  def export_subject_index_as_csv(work)
    subject_link = SubjectExporter::Exporter.new(self, work)

    subject_link.export
  end

  def export_subject_details_as_csv
    subjects = SubjectDetailsExporter::Exporter.new(self)

    subjects.export
  end

  def export_subject_coocurrence_as_csv
    subjects = SubjectCoocurrenceExporter::Exporter.new(self)

    subjects.export
  end

  def export_subject_distribution_as_csv(subject)
    subjects = SubjectDistributionExporter::Exporter.new(self, subject)

    subjects.export
  end

  def show_to?(user)
    (!self.restricted && self.works.present? && self.collection_blocks.where(user_id: user&.id).none?
    ) || (user && user.like_owner?(self)) || (user && user.collaborator?(self))
  end

  def create_categories
    #create two default categories
    category1 = Category.new(collection_id: self.id, title: "People")
    category1.save
    category2 = Category.new(collection_id: self.id, title: "Places")
    category2.save
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

  def normalize_friendly_id(string)
    super.truncate(240, separator: '-', omission: '').gsub('_', '-')
  end

  def uniquify_slug
    if DocumentSet.where(slug: self.slug).exists?
      self.slug = self.slug+'-collection'
    end
  end

  def blank_out_collection
    puts "Reset all data in the #{self.title} collection to blank"
    works = Work.where(collection_id: self.id)
    pages = Page.where(work_id: works.ids)

    #delete deeds for pages and articles (not work add deed)
    Deed.where(page_id: pages.ids).destroy_all
    Deed.where(article_id: self.articles.ids).destroy_all
    #delete articles
    Article.where(collection_id: self.id).destroy_all
    #delete categories (aside from the default)
    Category.where(collection_id: self.id).where.not(title: 'People').where.not(title: 'Places').destroy_all
    #delete notes
    Note.where(page_id: pages.ids).destroy_all
    #delete page_article_links
    PageArticleLink.where(page_id: pages.ids).destroy_all
    #update work transcription version
    works.each do |w|
      w.update_columns(transcription_version: 0)
    end
    #for each page, delete page versions, update all attributes, save
    pages.each do |p|
      p.page_versions.destroy_all
      p.update_columns(source_text: nil, created_on: Time.now, lock_version: 0, xml_text: nil,
                       status: Page.statuses[:new], source_translation: nil, xml_translation: nil,
                       translation_status: Page.translation_statuses[:new], search_text: "\n\n\n\n")
      p.save!
    end

    #fix user_id for page version (doesn't get set in this type of update)
    PageVersion.where(page_id: pages.ids).each do |v|
      v.user_id = self.owner.id
      v.save!
    end
    puts "#{self.title} collection has been reset"
  end

  def search_works(search)
    self.works.where("title LIKE ? OR searchable_metadata like ?", "%#{search}%", "%#{search}%")
  end

  def self.search(search)
    sql = "title like ? OR slug LIKE ? OR owner_user_id in (select id from \
           users where owner=1 and display_name like ?)"
    where(sql, "%#{search}%", "%#{search}%", "%#{search}%")
  end

  def sections
    Section.where(work_id: self.works.ids)
  end

  def default_orientation
    if !self[:default_orientation].nil?
      self[:default_orientation]
    elsif self[:field_based]
      'ttb'
    else
      'ltr'
    end
  end

  def is_public
    !restricted
  end

  def active?
    self.is_active
  end

  def set_next_untranscribed_page
    first_work = works.where.not(next_untranscribed_page_id: nil).order_by_incomplete.first
    first_page = first_work.nil? ? nil : first_work.next_untranscribed_page
    page_id = first_page.nil? ? nil : first_page.id

    update_columns(next_untranscribed_page_id: page_id)
  end

  def find_next_untranscribed_page_for_user(user)
    return nil unless has_untranscribed_pages?
    return next_untranscribed_page if user.can_transcribe?(next_untranscribed_page.work)

    public = works
      .where.not(next_untranscribed_page_id: nil)
      .unrestricted
      .order_by_incomplete

    return public.first.next_untranscribed_page unless public.empty?

    private = works
      .where.not(next_untranscribed_page_id: nil)
      .restricted
      .order_by_incomplete

    wk = private.find{ |w| user.can_transcribe?(w) }

    wk.nil? ? nil : wk.next_untranscribed_page
  end

  def has_untranscribed_pages?
    next_untranscribed_page.present?
  end

  def update_works_stats
    works = self.works.includes(:work_statistic)
    works_stats = get_works_stats_hash(works.ids)
    works.each do |w|
      w.work_statistic.recalculate_from_hash(works_stats[w.id])
    end
    calculate_complete
  end

  def enable_ocr
    works.update_all(ocr_correction: true)
    update_works_stats
  end

  def disable_ocr
    works.update_all(ocr_correction: false)
    update_works_stats
  end

  def get_works_stats_hash(work_ids)
    stats = {}
    work_prototype = {
      transcription: {},
      translation: {},
      total: 0
    }

    transcription = Page.where(work_id: work_ids).group(:work_id, :status).count
    translation = Page.where(work_id: work_ids).group(:work_id, :translation_status).count
    totals = Page.where(work_id: work_ids).group(:work_id).count

    transcription.each do |(id, status), value|
      stats[id] = work_prototype if stats[id].nil?
      stats[id][:transcription][status] = value
    end

    translation.each do |(id, status), value|
      stats[id] = work_prototype if stats[id].nil?
      stats[id][:translation][status] = value
    end

    totals.each do |id, value|
      stats[id] = work_prototype if stats[id].nil?
      stats[id][:total] = value
    end
    stats
  end

  #constant
  LANGUAGE_ARRAY = [['Afrikaans', 'af', ['af-ZA']],
                    ['አማርኛ', 'am', ['am-ET']],
                    ['Azərbaycanca', 'az', ['az-AZ']],
                    ['বাংলা', 'bn', ['bn-BD', 'বাংলাদেশ'], ['bn-IN', 'ভারত']],
                    ['Bahasa Indonesia', 'id', ['id-ID']],
                    ['Bahasa Melayu', 'ms', ['ms-MY']],
                    ['Català', 'ca', ['ca-ES']],
                    ['Čeština', 'cs', ['cs-CZ']],
                    ['Dansk', 'da', ['da-DK']],
                    ['Deutsch', 'de', ['de-DE']],
                    ['English', 'en', ['en-AU', 'Australia'], ['en-CA', 'Canada'], ['en-IN', 'India'], ['en-KE', 'Kenya'], ['en-TZ', 'Tanzania'], ['en-GH', 'Ghana'], ['en-NZ', 'New Zealand'], ['en-NG', 'Nigeria'], ['en-ZA', 'South Africa'], ['en-PH', 'Philippines'], ['en-GB', 'United Kingdom'], ['en-US', 'United States']],
                    ['Español', 'es', ['es-AR', 'Argentina'], ['es-BO', 'Bolivia'], ['es-CL', 'Chile'], ['es-CO', 'Colombia'], ['es-CR', 'Costa Rica'], ['es-EC', 'Ecuador'], ['es-SV', 'El Salvador'], ['es-ES', 'España'], ['es-US', 'Estados Unidos'], ['es-GT', 'Guatemala'], ['es-HN', 'Honduras'], ['es-MX', 'México'], ['es-NI', 'Nicaragua'], ['es-PA', 'Panamá'], ['es-PY', 'Paraguay'], ['es-PE', 'Perú'], ['es-PR', 'Puerto Rico'], ['es-DO', 'República Dominicana'], ['es-UY', 'Uruguay'], ['es-VE', 'Venezuela']],
                    ['Euskara', 'eu', ['eu-ES']],
                    ['Filipino', 'fil', ['fil-PH']],
                    ['Français', 'fr', ['fr-FR']],
                    ['Basa Jawa', 'jv', ['jv-ID']],
                    ['Galego', 'gl', ['gl-ES']],
                    ['ગુજરાતી', 'gu', ['gu-IN']],
                    ['Hrvatski', 'hr', ['hr-HR']],
                    ['IsiZulu', 'zu', ['zu-ZA']],
                    ['Íslenska', 'is', ['is-IS']],
                    ['Italiano', 'is', ['it-IT', 'Italia'], ['it-CH', 'Svizzera']],
                    ['ಕನ್ನಡ', 'kn', ['kn-IN']],
                    ['ភាសាខ្មែរ', 'km', ['km-KH']],
                    ['Latviešu', 'lv', ['lv-LV']],
                    ['Lietuvių', 'lt', ['lt-LT']],
                    ['മലയാളം', 'ml', ['ml-IN']],
                    ['मराठी', 'mr', ['mr-IN']],
                    ['Magyar', 'hu', ['hu-HU']],
                    ['ລາວ', 'lo', ['lo-LA']],
                    ['Nederlands', 'nl', ['nl-NL']],
                    ['नेपाली भाषा', 'ne', ['ne-NP']],
                    ['Norsk bokmål', 'nb', ['nb-NO']],
                    ['Polski', 'pl', ['pl-PL']],
                    ['Português', 'pt', ['pt-BR', 'Brasil'], ['pt-PT', 'Portugal']],
                    ['Română', 'ro', ['ro-RO']],
                    ['සිංහල', 'si', ['si-LK']],
                    ['Slovenščina', 'sl', ['sl-SI']],
                    ['Basa Sunda', 'su', ['su-ID']],
                    ['Slovenčina', 'sk', ['sk-SK']],
                    ['Suomi', 'fi', ['fi-FI']],
                    ['Svenska', 'sv', ['sv-SE']],
                    ['Kiswahili', 'sw', ['sw-TZ', 'Tanzania'], ['sw-KE', 'Kenya']],
                    ['ქართული', 'ka', ['ka-GE']],
                    ['Հայերեն', 'hy', ['hy-AM']],
                    ['தமிழ்', 'ta', ['ta-IN', 'இந்தியா'], ['ta-SG', 'சிங்கப்பூர்'], ['ta-LK', 'இலங்கை'], ['ta-MY', 'மலேசியா']],
                    ['తెలుగు', 'te', ['te-IN']],
                    ['Tiếng Việt', 'vi', ['vi-VN']],
                    ['Türkçe', 'tr', ['tr-TR']],
                    ['اُردُو', 'ur', ['ur-PK', 'پاکستان'], ['ur-IN', 'بھارت']],
                    ['Ελληνικά', 'el', ['el-GR']],
                    ['български', 'bg', ['bg-BG']],
                    ['Pусский', 'ru', ['ru-RU']],
                    ['Српски', 'sr', ['sr-RS']],
                    ['Українська', 'uk', ['uk-UA']],
                    ['한국어', 'ko', ['ko-KR']],
                    ['中文', 'cmn', 'yue', ['cmn-Hans-CN', '普通话 (中国大陆)'], ['cmn-Hans-HK', '普通话 (香港)'], ['cmn-Hant-TW', '中文 (台灣)'], ['yue-Hant-HK', '粵語 (香港)']],
                    ['日本語', 'ja', ['ja-JP']],
                    ['हिन्दी', 'hi', ['hi-IN']],
                    ['ภาษาไทย', 'th', ['th-TH']]];

  protected

  def set_transcription_conventions
    unless self.transcription_conventions.present?
      self.transcription_conventions = "<p><b>Transcription Conventions</b>\n<ul><li><i>Spelling: </i>Use original spelling if possible.</li>\n <li><i>Capitalization: </i>Retain original capitalization.</li>\n<li><i>Punctuation: </i>Use original punctuation when possible.</li>\n<li><i>Line Breaks: </i>Hit <code>Enter</code> once after each line ends.  Two returns indicate a new paragraph, whether indicated by a blank line or by indentation in the original.</li></ul>"
    end
  end

    DEFAULT_HELP_TEXT = <<ENDHELP
    <h2> Transcribing</h2>
    <p> Once you sign up for an account, a new Transcribe tab will appear above each page.</p>
    <p> You can create or edit transcriptions by modifying the text entry field and saving. Each modification is stored as a separate version of the page, so that it should be easy to revert to older versions if necessary.</p>
    <p> Registered users can also add notes to pages to comment on difficult words, suggest readings, or discuss the texts.</p>
    <h3>Helpful Documentation</h3>
    <p><a href="https://content.fromthepage.com/project-owner-documentation/advanced-mark-up/">Advanced Markup</a><br><br>
    <a href="https://content.fromthepage.com/project-owner-documentation/table-encoding/">Table Encoding</a><br><br>
    <a href="https://content.fromthepage.com/project-owner-documentation/encoding-formula-with-latex/">Encoding mathematical and scientific formula with LaTex</a></p>
ENDHELP

  def set_help
    unless self.help.present?
      self.help = DEFAULT_HELP_TEXT
    end
  end

  def set_link_help
    unless self.link_help.present?
      self.link_help = "<h2>Linking Subjects</h2>\n<p> To create a link within a transcription, surround the text with double square braces.</p>\n<p> Example: Say that we want to create a subject link for &ldquo;Dr. Owen&rdquo; in the text:</p>\n<code> Dr. Owen and his wife came by for fried chicken today.</code>\n<p> Place <code>[[ and ]]</code> around Dr Owen like this:</p>\n<code>[[Dr. Owen]] and his wife came by for fried chicken today.</code>\n<p> When you save the page, a new subject will be created for &ldquo;Dr. Owen&rdquo;, and the page will be added to its index. You can add an article about Dr. Owen&mdash;perhaps biographical notes or references&mdash;to the subject by clicking on &ldquo;Dr. Owen&rdquo; and clicking the Edit tab.</p>\n<p> To create a subject link with a different name from that used within the text, use double braces with a pipe as follows: <code>[[official name of subject|name used in the text]]</code>. For example:</p>\n<code> [[Dr. Owen]] and [[Dr. Owen's wife|his wife]] came by for fried chicken today.</code>\n<p> This will create a subject for &ldquo;Dr. Owen's wife&rdquo; and link the text &ldquo;his wife&rdquo; to that subject.</p></a>\n<h2> Renaming Subjects</h2>\n<p> In the example above, we don't know Dr. Owen's wife's name, but created a subject for her anyway. If we later discover that her name is &ldquo;Juanita&rdquo;, all we have to do is edit the subject title:</p>\n<ol><li>Click on &ldquo;his wife&rdquo; on the page, or navigate to &ldquo;Dr. Owen's wife&rdquo; on the home page for the project.</li>\n<li>Click the Edit tab.</li>\n<li> Change &ldquo;Dr. Owen's wife&rdquo; to &ldquo;Juanita Owen&rdquo;.</li></ol>\n<p> This will change the links on the pages that mention that subject, so our page is automatically updated:</p>\n    <code>[[Dr. Owen]] and [[Juanita Owen|his wife]] came by for fried chicken today.</code>\n<h2> Combining Subjects</h2>\n<p> Occasionally you may find that two subjects actually refer to the same person. When this happens, rather than painstakingly updating each link, you can use the Combine button at the bottom of the subject page.</p>\n <p> For example, if one page reads:</p>\n<code>[[Dr. Owen]] and [[Juanita Owen|his wife]] came by for [[fried chicken]] today.</code>\n<p> while a different page contains</p>\n<code> Jim bought a [[chicken]] today.</code>\n<p> you can combine &ldquo;chicken&rdquo; with &ldquo;fried chicken&rdquo; by going to the &ldquo;chicken&rdquo; article and reviewing the combination suggestions at the bottom of the screen. Combining &ldquo;fried chicken&rdquo; into &ldquo;chicken&rdquo; will update all links to point to &ldquo;chicken&rdquo; instead, copy any article text from the &ldquo;fried chicken&rdquo; article onto the end of the &ldquo;chicken&rdquo; article, then delete the &ldquo;fried chicken&rdquo; subject.</p>\n<h2> Auto-linking Subjects</h2>\n<p> Whenever text is linked to a subject, that fact can be used by the system to suggest links in new pages. At the bottom of the transcription screen, there is an Autolink button. This will refresh the transcription text with suggested links, which should then be reviewed and may be saved.</p>\n<p> Using our example, the system already knows that &ldquo;Dr. Owen&rdquo; links to &ldquo;Dr. Owen&rdquo; and &ldquo;his wife&rdquo; links to &ldquo;Juanita Owen&rdquo;. If a new page reads:</p>\n<code> We told Dr. Owen about Sam Jones and his wife.</code>\n<p> pressing Autolink will suggest these links:</p>\n<code> We told [[Dr. Owen]] about Sam Jones and [[Juanita Owen|his wife]].</code>\n<p> In this case, the link around &ldquo;Dr. Owen&rdquo; is correct, but we must edit the suggested link that incorrectly links Sam Jones's wife to &ldquo;Juanita Owen&rdquo;. The autolink feature can save a great deal of labor and prevent collaborators from forgetting to link a subject they previously thought was important, but its suggestions still need to be reviewed before the transcription is saved.</p>"
    end
  end

  def user_help
    User.find(self.owner_user_id).help
  end

  public :user_help

end
