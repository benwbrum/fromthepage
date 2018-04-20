class DeedDTO
attr_accessor :collection, :deed, :work, :user,:created_at

  def initialize(deed)
    @collection = deed.collection.title  
    @deed = deed
    @work = deed.work.title
    @id = deed.id
    @deed_type = deed.deed_type
    @page = deed.page
    @user = deed.user.display_name
    @created_at = deed.created_at
    @updated_at = deed.updated_at
  end   
end  
