class Transcription < Contribution
  acts_as_votable cacheable_strategy: :update_columns
  
  def initialize(args = {})
    super(args)
  end

end
