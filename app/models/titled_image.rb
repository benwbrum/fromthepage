class TitledImage < ActiveRecord::Base
  belongs_to :image_set
  acts_as_list :scope => :image_set
  
  def original_file(raw=false)
    if raw || nil == image_set.path
      self[:original_file]
    else
      File.join(image_set.path, self[:original_file])
    end
  end
  
  # tested
  def crop_file
    original_file.sub(/.jpg/, "_crop.jpg")
  end
  
  def shrunk_file(factor=nil)
    factor ||= self.image_set.original_to_base_halvings
    if 0 == factor
      original_file
    else
      original_file.sub(/.jpg/, "_#{factor}.jpg")
    end
  end
end
