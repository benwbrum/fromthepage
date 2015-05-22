class ExportContext
  attr_accessor  :div_stack, :translation_mode
  

  def initialize
    self.div_stack = []
    self.translation_mode = false   
  end
  
end
  