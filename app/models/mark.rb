class Mark < ActiveRecord::Base
  attr_accessible :text, :coordinates, :type, :shape_type

  belongs_to :page
  
  validates :coordinates, :text, presence: true

  def initialize(args={})
    super(args)
  end

end
