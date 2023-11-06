class NoteDatatable < AjaxDatatablesRails::ActiveRecord 
  extend Forwardable

  def_delegators :@view, 
    :link_to, 
    :time_tag,
    :time_ago_in_words,
    :collection_display_page_path,
    :collection_read_work_path,
    :collection_path,
    :user_profile_path

  def initialize(params, options = {})
    @view = options[:view_context]
    @collection = Collection.find(options[:collection_id]) if options[:collection_id]
    super 
  end

  def view_columns
    if @collection.metadata_only_entry?
      @view_columns ||= {
      userpic:    { searchable: false, orderable: false },
      user:       { source: "User.display_name"},      
      note:       { source: "Note.title"},
      work:       { source: "Work.title"},
      collection: { source: "Collection.title" },
      time:       { source: "Note.created_at" }
    }
    else
      @view_columns ||= {
      userpic:    { searchable: false, orderable: false },
      user:       { source: "User.display_name"},      
      note:       { source: "Note.title"},
      page:       { source: "Page.title"},
      work:       { source: "Work.title"},
      collection: { source: "Collection.title" },
      time:       { source: "Note.created_at" }
    }
    end
  end

  def data
    if @collection.metadata_only_entry?
      records.map do |record|
        {
          userpic:    userpic(record),
          user:       link_to(record.user&.display_name, user_profile_path(record.user)),
          note:       record.title,
          work:       link_to(record.work.title, collection_read_work_path(record.collection.owner, record.collection, record.work)),
          collection: link_to(record.collection.title, collection_path(record.collection.owner, record.collection)),
          time:       timestamp(record)
        }
      end
    else
      records.map do |record|
        {
          userpic:    userpic(record),
          user:       link_to(record.user&.display_name, user_profile_path(record.user)),
          note:       record.title,
          page:       link_to(record.page.title, collection_display_page_path(record.collection.owner, record.collection, record.work, record.page)),
          work:       link_to(record.work.title, collection_read_work_path(record.collection.owner, record.collection, record.work)),
          collection: link_to(record.collection.title, collection_path(record.collection.owner, record.collection)),
          time:       timestamp(record)
        }
      end
    end
  end

  def get_raw_records
    if @collection
      if @collection.metadata_only_entry?
        @collection.notes
          .joins(:collection, :work, :user)
          .reorder('')
      else
        @collection.notes
          .joins(:collection, :page, :work, :user)
          .reorder('')
      end
    else
      Note.includes(:collection).where("collections.restricted = 0")
        .joins(:collection, :page, :work, :user)
        .reorder('')
    end
  end

  private

  def userpic(record)
    link_to user_profile_path(record.user) do
      ActionController::Base.new.render_to_string("shared/_profile_picture", :locals => { :user => record.user, :gravatar_size => nil })
    end
  end

  def timestamp(record)
    time_tag(record.created_at, class: 'small fglight') do
      I18n.t('time_ago_in_words', time: time_ago_in_words(record.created_at))
    end
  end

end
