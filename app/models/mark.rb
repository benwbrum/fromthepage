class Mark < ActiveRecord::Base
  attr_accessible :coordinates, :text_type, :shape_type, :page_id

  belongs_to :page
  belongs_to :transcription
  belongs_to :translation
  
  validates :coordinates, presence: true

  def initialize(args={})
    super(args)
    puts "lalalalalaljeje"
    puts args.inspect
    if(args[:transcription_text])
      self.transcription = Transcription.new({text: args[:transcription_text]})
      self.transcription.mark = self
    end
    if(args[:translation_text])
      self.translation = Translation.new({text: args[:translation_text]})
      self.translation.mark = self
    end
  end

  def valueObject
    {
      id: self.id,
      text_type: self.text_type,
      shape_type: self.shape_type,
      coordinates: JSON.parse(self.coordinates),
      page_id: self.page_id,
      transcription: self.transcription,
      translation: self.translation
    } 
  end
end
