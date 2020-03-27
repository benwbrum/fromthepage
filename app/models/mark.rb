class Mark < ActiveRecord::Base
  attr_accessible :coordinates, :text_type, :shape_type, :page_id, :layer_id

  belongs_to :page
  belongs_to :transcription
  belongs_to :translation
  belongs_to :semanticContribution
  
  has_many :contributions
  
  validates :coordinates, presence: true

  def initialize(args={}, user)
    super(args)
    if(args[:transcription_text])
      self.transcription = Transcription.new({text: args[:transcription_text]})
      self.transcription.mark = self
      self.transcription.user = user
    end
    if(args[:translation_text])
      self.translation = Translation.new({text: args[:translation_text]})
      self.translation.mark = self
      self.translation.user = user
    end
    if(args[:semantic_text])
      self.semanticContribution = SemanticContribution.new({text: args[:semantic_text], schema_type: args[:schema_type]})
      self.semanticContribution.mark = self
      self.semanticContribution.user = user
    end
  end

  def valueObject
    {
      id: self.id,
      text_type: self.text_type,
      shape_type: self.shape_type,
      coordinates: JSON.parse(self.coordinates),
      page_id: self.page_id,
      layer_id: self.layer_id,
      transcription: self.transcription,
      translation: self.translation,
      semanticContribution: self.semanticContribution
    }
  end
end
