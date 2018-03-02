class CollectionDashboard

   # método inicializar clase
  def initialize(collections)  
    # atributos   
    @collections = collections  
    @deeds = Array.new
  end  
  
 def addDeeds(deeds)
  @deeds = deeds;   
 end

end  