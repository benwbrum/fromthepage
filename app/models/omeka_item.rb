class OmekaItem < ActiveRecord::Base
  attr_accessible :coverage, :creator, :description, :format, :omeka_collection_id, :omeka_id, :omeka_url, :rights, :subject, :title
  belongs_to :user
  belongs_to :omeka_site
  belongs_to :work
  has_many :omeka_files

  def client_files
    client_item = omeka_site.client.get_item(omeka_id)
    client_item.files
  end

  def import(fromthepage_collection=nil)
    client_item = omeka_site.client.get_item(omeka_id)

    unless fromthepage_collection
      if omeka_collection_id
        # look for a parent collection mirror object in FromThePage
        omeka_collection = OmekaCollection.where(:omeka_id => omeka_collection_id).first
        unless omeka_collection
          omeka_collection = create_mirror_collection(client_item.collection)
        end
      end
      # if the item was in an Omeka collection, there is now a mirror object  
      if omeka_collection.collection
        fromthepage_collection = omeka_collection.collection
      else
        fromthepage_collection = create_mirror_collection(omeka_collection)
      end
    end

    # now create mirror file records
    client_item.files.each do |client_file|
      if client_file.data.mime_type.match(/image/)
        self.omeka_files <<
          OmekaFile.new({
            :omeka_id => client_file.data.id,
            :mime_type => client_file.data.mime_type,
            :fullsize_url => client_file.data.file_urls.original,
            :thumbnail_url => client_file.data.file_urls.thumbnail,
            :original_filename => client_file.data.original_filename,
            :omeka_order => client_file.data.order
          })
      end
    end

    # now create FromThePage works and pages
    work = Work.new
    work.owner = User.current_user
    work.title = title
    work.description = description
    work.physical_description = format
    work.author = creator
    work.collection=fromthepage_collection
    work.save!
    self.omeka_files.each do |omeka_file|
      page = Page.new
      page.title = omeka_file.omeka_order || File.basename(omeka_file.original_filename)
      work.pages << page #necessary to make acts_as_list work here
      work.save!
      omeka_file.page_id = page.id
      omeka_file.save!
    end
    work.save!
    record_deed(work)

    self.work = work
    self.save!

  end



  def self.new_from_site_item_id(site, id)
    client_item = site.client.get_item(id)

    attrs = attrs_from_dublin_core(client_item.dublin_core)

    new_item = OmekaItem.new(attrs)
    new_item.omeka_collection_id = client_item.data.collection.id if client_item.data.collection
    new_item.omeka_id = client_item.data.id
    new_item.omeka_url = client_item.data.url
    new_item.omeka_site=site

    new_item
  end


  def self.attrs_from_dublin_core(dc)
    {
      :title => dc.title,
      :subject => dc.subject,
      :description => dc.description,
      :rights => dc.rights,
      :creator => dc.creator,
      :format => dc.format,
      :coverage => dc.coverage,
    }
  end

  def needs_refresh?
    # Private S3 buckets expire after a certain amout of time.
    # First determine whether this is on a private S3 bucket
    # Then determine whether the expiration date is in the past
    omeka_files.first[:thumbnail_url].match(/Expires=(\d+)/) && $1.to_i < Time.now.to_i
  end
  
  def refresh_urls
    client_item = omeka_site.client.get_item(omeka_id)
    fresh_files =  client_item.files.map { |e| [e.data.mime_type, e.data.id, e.data.file_urls.thumbnail, e.data.file_urls.original] }

    fresh_files.each_with_index do |(mime_type, omeka_id, thumbnail_url, fullsize_url), i|
      if mime_type.match(/image/)
        omeka_file = self.omeka_files.where(:omeka_id => omeka_id).first
        if omeka_file
          omeka_file.fullsize_url = fullsize_url
          omeka_file.thumbnail_url = thumbnail_url
          omeka_file.save!
        end
      end
    end
  end


protected

  def create_mirror_collection(client_collection)
    omeka_collection = OmekaCollection.new
    omeka_collection.omeka_id = client_collection.data.id
    omeka_collection.title = client_collection.dublin_core.title
    omeka_collection.description = client_collection.dublin_core.description
    omeka_collection.omeka_site = omeka_site
    omeka_collection.save!
    
    omeka_collection
  end

  def create_fromthepage_collection(omeka_collection)
    # create a FromThePage collection
    fromthepage_collection = Collection.new
    fromthepage_collection.owner = User.current_user
    fromthepage_collection.title = omeka_collection.title
    fromthepage_collection.intro_block = omeka_collection.description
    fromthepage_collection.save!

    omeka_collection.collection = fromthepage_collection
    omeka_collection.save!    
    
    fromthepage_collection
  end


  def record_deed(work)
    deed = Deed.new
    deed.work = work
    deed.deed_type = Deed::WORK_ADDED
    deed.collection = work.collection
    deed.user = work.owner
    deed.save!
  end

end
