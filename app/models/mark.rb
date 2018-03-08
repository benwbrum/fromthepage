class Mark < ActiveRecord::Base
  attr_accessible :text, :coordinates, :text_type, :shape_type

  belongs_to :page
  
  validates :coordinates, :text, presence: true

  def initialize(args={})
    super(args)
  end

  def valueObject
    # MarkValueObject.new(self)
    {
      id: self.id,
      text: self.text,
      text_type: self.text_type ,
      shape_type: self.shape_type,
      coordinates: JSON.parse(self.coordinates),
      page_id: self.page_id
    } 
  end
end
