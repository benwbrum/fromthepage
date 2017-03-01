class DeleteOrphanedData < ActiveRecord::Migration
  def change
    #delete works for which there is no collection
    Work.all.each {|w| w.destroy unless w.collection}
    
    #delete pages for which there are no works
    Page.all.each {|p| p.destroy unless p.work}
    
    #delete document sets for which there is no collection
    DocumentSet.all.each {|d| d.destroy unless d.collection}

    #delete notes for which there is no collection
    Note.all.each {|n| n.destroy unless n.collection}
  end
end
