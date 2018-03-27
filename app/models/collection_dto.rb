class CollectionDTO
attr_accessor :collection, :works,:notes

 # método inicializar clase
 def initialize(collection,works,notes)  
  	@collection=collection
   	@works = works
   	@notes = notes
   end  
end  