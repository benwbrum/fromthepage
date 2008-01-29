class TitledImage < ActiveRecord::Base
  belongs_to :image_set
  acts_as_list :scope => :image_set
  
  def crop_file
    self[:original_file].sub(/.jpg/, "_crop.jpg")
  end
  
  def shrunk_file(factor = 2)
    if 0 == factor
      self[:original_file]
    else
      self[:original_file].sub(/.jpg/, "_#{factor}.jpg")
    end
  end
end
