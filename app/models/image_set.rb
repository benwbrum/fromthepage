class ImageSet < ActiveRecord::Base
  has_many :titled_images, :order => :position
  belongs_to :owner, :class_name => "User", :foreign_key => "owner_user_id"
  
  def page_count
    if titled_images == nil
      return 0
    end
    titled_images.size
  end
  
  def summary
    if page_count == 0
      return 'empty'
    end
    desc = ''
    if page_count <= 4
      titled_images.each { |image| desc = "#{desc}, #{image.title}" }
      return desc
    end
    desc += "#{titled_images[0].title}, #{titled_images[1].title} ... #{titled_images[page_count-1].title}, #{titled_images[page_count-2].title}"
    return desc
  end
end
